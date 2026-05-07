# app/models/employee.rb

class Employee < ApplicationRecord
  include AddressConcern
  include RoleConcern
  include Employee::PermissionConcern
  include TagConcern
  include Discard::Model

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :user, optional: true


  has_many :role_appointments, as: :appoint_to, dependent: :destroy
  has_many :roles, through: :role_appointments

  has_many :service_appointments, dependent: :destroy, as: :appoint_to
  has_many :services, through: :service_appointments

  has_many :employee_group_appointments, dependent: :destroy, as: :appoint_to
  has_many :employee_groups, through: :employee_group_appointments

  has_many :department_appointments, dependent: :destroy, as: :appoint_to
  has_many :departments, through: :department_appointments

  has_many :tag_appointments, dependent: :destroy, as: :appoint_to
  has_many :tags, through: :tag_appointments

  has_many :bookings, as: :appoint_from, dependent: :destroy

  # --- Enums ---
  enum :business_type, {
    owner: 0,
    full_time: 1,
    part_time: 2,
    contractor: 3,
    intern: 4
  }
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :business_type, presence: true
  validate :only_one_owner_per_company, on: :create

  before_discard :prevent_discard_if_owner
  before_destroy :prevent_destroy_if_owner

  private

  def only_one_owner_per_company
    return unless business_type.to_s == "owner" && company_id.present?

    # Only one owner employee per company
    # Allow if this employee is updating their own record (same id)
    return if persisted? && self.id == Employee.find_by(company_id: company_id, business_type: :owner)&.id

    owner_exists = Employee.where(company_id: company_id, business_type: :owner)
      .where.not(id: self.id)
      .exists?

    if owner_exists
      errors.add(:base, "Only one owner employee is allowed per company.")
    end
  end

  def prevent_discard_if_owner
    return unless business_type.to_s == "owner"
    errors.add(:base, "Owner employee cannot be discarded.")
    throw(:abort)
  end

  def prevent_destroy_if_owner
    return unless business_type.to_s == "owner"
    errors.add(:base, "Owner employee cannot be destroyed.")
    throw(:abort)
  end
end
