class Role < ApplicationRecord
  include TagConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  CRUD_ACTIONS = %w[create read update delete].freeze

  # --- Associations ---
  # REASON: When a Role's timestamp is updated (either directly or via PolicyAppointment), it touches the Company. This ensures the Company's cache_key changes.
  belongs_to :company, touch: true
  belongs_to :branch, optional: true

  has_many :policy_appointments, dependent: :destroy, as: :appoint_to
  has_many :policies, through: :policy_appointments

  has_many :tag_appointments, dependent: :destroy, as: :appoint_to
  has_many :tags, through: :tag_appointments

  has_many :employee_group_appointments, dependent: :destroy, as: :appoint_to
  has_many :employee_groups, through: :employee_group_appointments

  has_many :role_appointments, dependent: :destroy
  has_many :employee_groups, through: :role_appointments, source: :appoint_to, source_type: "EmployeeGroup"
  has_many :employees, through: :role_appointments, source: :appoint_to, source_type: "Employee"
  has_many :customer_groups, through: :role_appointments, source: :appoint_to, source_type: "CustomerGroup"
  has_many :customers, through: :role_appointments, source: :appoint_to, source_type: "Customer"
  has_many :departments, through: :role_appointments, source: :appoint_to, source_type: "Department"

  # This fires whenever the Role is touched (e.g., by a PolicyAppointment change)
  after_touch :invalidate_employee_caches

  # --- Soft Deletion (Discard) ---
  # If you are using a gem like 'Discard' or similar for soft deletion:
  # include Discard::Model
  # default_scope -> { kept }

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
    notification_group: 19,
    payment_method: 20
  }, prefix: :model_type

  # --- Validations ---
  validates :name,
          presence: true,
          length: { maximum: 100 },
          uniqueness: {
            scope: :company_id,
            message: "A role with this name already exists."
          }

  validates :business_type, presence: true

  # This fires whenever the Role is touched (e.g., by a PolicyAppointment change)
  after_touch :invalidate_employee_caches

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

      appointment = PolicyAppointment.find_or_create_by!(
        company: company,
        policy: policy,
        appoint_to: self
      )

      appointment.update!(workflow_status: :inactive) if appointment.new_record?
    end
  end

  private

  def invalidate_employee_caches
    # Efficiently update the timestamp of all associated employees
    # without loading them into memory or running their callbacks.
    employees.update_all(updated_at: Time.current)
  end
end
