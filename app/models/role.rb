class Role < ApplicationRecord
  # --- Associations ---
  belongs_to :company

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
  enum :kind, { 
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
  # validates :status, presence: true
  # validates :kind, presence: true
end