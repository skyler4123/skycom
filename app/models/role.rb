class Role < ApplicationRecord
  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true

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



  # --- Soft Deletion (Discard) ---
  # If you are using a gem like 'Discard' or similar for soft deletion:
  # include Discard::Model
  # default_scope -> { kept }

  # --- Enums ---
  # Using full path to avoid potential method clashes, as seen in Employee model
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  # Standardized role kinds for categorization
  enum :business_type, {
    administrative: 0,
    management: 1,
    technical: 2,
    support: 3
  }
  # --- Model Types Enum ---
  enum :model_type, {
    global: 0,
    company_group: 1,
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
            scope: :company_group_id,
            message: "A role with this name already exists."
          }

  validates :business_type, presence: true
end
