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
  enum :status, { 
    active: 0, 
    pending: 1, 
    archived: 2 
  }
  
  # Standardized role kinds for categorization
  enum :business_type, { 
    administrative: 0, 
    management: 1, 
    technical: 2, 
    support: 3 
  }
  
  # --- Validations ---
  validates :name,
          presence: true,
          length: { maximum: 100 },
          uniqueness: { 
            scope: :company_id, 
            message: "A role with this name already exists." 
          }
  validates :status, presence: true
  validates :business_type, presence: true
end