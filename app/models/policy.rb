class Policy < ApplicationRecord
  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true

  has_many :policy_appointments, dependent: :destroy
  has_many :roles, through: :policy_appointments, source: :appoint_to, source_type: "Role"

  has_many :tag_appointments, dependent: :destroy, as: :appoint_to
  has_many :tags, through: :tag_appointments
  # --- Soft Deletion (Discard) ---
  # If you are using a gem like 'Discard' or similar for soft deletion:
  # include Discard::Model 
  # default_scope -> { kept } 

  # --- Enums ---
  # Using full path to avoid potential method clashes
  enum :status, { 
    active: 0, 
    pending: 1, 
    archived: 2 
  }
  
  # Policy business_types based on common organizational categories
  enum :business_type, { 
    security: 0, 
    regulatory: 1, 
    operational: 2, 
    compliance: 3 
  }
  
  # --- Validations ---
  validates :name, presence: true, length: { maximum: 150 }
  validates :resource, presence: true
  validates :action, presence: true
  
  # CRITICAL: Enforce uniqueness of the policy name scoped to the company.
  # This prevents two policies within the same company from having the same name.
  validates :name, 
            uniqueness: { 
              scope: :company_id, 
              message: "A policy with this name already exists in this company." 
            }
            
  validates :status, presence: true
  validates :kind, presence: true
end