# frozen_string_literal: true

# Role — Atomic purpose: company-scoped permission role that collects ABAC
# policies and is granted to holders (employees, customers, groups, departments).
#
# Why it exists: policies describe individual rules; a role bundles them so the
# same permission set can be attached to many holders without duplicating grants
# (see docs/ABAC.md).
# How it works: belongs to company (touch) and optional branch; policies attach
# through PolicyRoleAppointment, and holders attach through their own
# <Holder>RoleAppointment tables. Touching a role invalidates employee permission
# caches, and changes are logged in PermissionLog.
# Main associations: belongs_to :company (touch), :branch (optional); has_many
# :policies through :policy_role_appointments; has_many :employees, :customers,
# :customer_groups, :departments, :employee_groups through their role
# appointments; has_many :permission_logs (dependent: :nullify).
class Role < ApplicationRecord
  include TagConcern

  CRUD_ACTIONS = %w[create read update delete].freeze
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  # Using full path to avoid potential method clashes, as seen in Employee model
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  # Standardized role kinds for categorization
  enum :business_type, {
    owner: 0,
    administrative: 1,
    management: 2,
    technical: 3,
    support: 4
  }
  # --- Model Types Enum ---
  enum :model_type, {
    global: 0,
    company: 1,
    comapny: 2,
    employee_group: 3,
    employee: 4,
    facility_group: 5,
    facility: 6,
    service_group: 7,
    service: 8,
    product_group: 9,
    product: 10,
    customer_group: 11,
    customer: 12,
    order: 13,
    period: 14,
    payment_method_appointment: 15,
    task_group: 16,
    project_group: 17,
    cart_group: 18,
    payment_method: 20
  }, prefix: :model_type
  # --- Associations ---
  # REASON: When a Role's timestamp is updated (either directly or via PolicyRoleAppointment), it touches the Company. This ensures the Company's cache_key changes.
  belongs_to :company, touch: true
  belongs_to :branch, optional: true

  has_many :policy_role_appointments, dependent: :destroy
  has_many :policies, through: :policy_role_appointments
  has_many :permission_logs, dependent: :nullify

  has_many :employee_role_appointments, dependent: :destroy
  has_many :employees, through: :employee_role_appointments
  has_many :customer_role_appointments, dependent: :destroy
  has_many :customers, through: :customer_role_appointments
  has_many :customer_group_role_appointments, dependent: :destroy
  has_many :customer_groups, through: :customer_group_role_appointments
  has_many :department_role_appointments, dependent: :destroy
  has_many :departments, through: :department_role_appointments
  has_many :employee_group_role_appointments, dependent: :destroy
  has_many :employee_groups, through: :employee_group_role_appointments

  # --- Validations ---
  validates :name,
          presence: true,
          length: { maximum: 100 },
          uniqueness: {
            scope: :company_id,
            message: "A role with this name already exists."
          }
  validates :business_type, presence: true
  # This fires whenever the Role is touched (e.g., by a PolicyRoleAppointment change)
  after_touch :invalidate_employee_caches

  after_create :ensure_paired_notification_tag
  after_update :rename_paired_notification_tag, if: :saved_change_to_name?
  before_destroy :destroy_paired_notification_tag

  def setup_policies_for!(resource_name)
    CRUD_ACTIONS.each do |action|
      policy = Policy.find_or_create_by!(
        name: "Can #{action} #{resource_name}",
        company: company,
        resource: resource_name,
        action: action
      ) do |p|
        p.description = "Allows #{action} operations on #{resource_name}"
        p.business_type = :operational
        p.lifecycle_status = :active
        p.branch_id = company.branches.first&.id
      end

      appointment = PolicyRoleAppointment.find_or_create_by!(
        company: company,
        policy: policy,
        role: self
      )

      appointment.update!(workflow_status: :inactive) if appointment.new_record?
    end
  end

  def paired_tag_name
    "All #{name}"
  end

  private

  def skip_paired_tag?
    name == OWNER_BUSINESS_TYPE
  end

  def ensure_paired_notification_tag
    return if skip_paired_tag?

    NotificationTag.find_or_create_by!(company: company, name: paired_tag_name) do |tag|
      tag.description = "Broadcasts to all employees with the #{name} role."
      tag.business_type = :system
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def rename_paired_notification_tag
    old_name = saved_change_to_name.first
    old_paired = "All #{old_name}"

    if skip_paired_tag?
      NotificationTag.find_by(company: company, name: old_paired)&.destroy_paired_for_role!
      return
    end

    return if old_paired == paired_tag_name

    tag = NotificationTag.find_by(company: company, name: old_paired)
    if tag
      tag.update!(name: paired_tag_name)
    else
      ensure_paired_notification_tag
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    nil
  end

  def destroy_paired_notification_tag
    return if skip_paired_tag?

    NotificationTag.find_by(company: company, name: paired_tag_name)&.destroy_paired_for_role!
  end

  def invalidate_employee_caches
    # Bump every holder's version and drop the cached employee hash: touch_all
    # updates updated_at in one query, but update_all/touch_all do not run the
    # after_commit refresh, so the sync_cache entry would keep the old
    # timestamp and the versioned permission keys would stay stale.
    employee_rows = employees.pluck(:user_id, :company_id)

    employee_rows.each do |user_id, company_id|
      next if user_id.blank?

      Rails.sync_cache.delete(
        CacheKeyService.employee_record(user_id: user_id, company_id: company_id)
      )
    end

    employees.touch_all
  end
end
