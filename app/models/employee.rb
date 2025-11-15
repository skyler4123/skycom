class Employee < ApplicationRecord
  # --- Associations ---
  belongs_to :company
  belongs_to :user # user_id is nullable in the migration

  # --- Soft Deletion (Discard) ---
  # If you are using a gem like 'Discard' or similar for soft deletion:
  # include Discard::Model 
  # default_scope -> { kept } # Show only non-discarded records by default
  # Note: The raw migration includes the 'discarded_at' column and index.
  
  # --- Enums ---
  # The values are taken from the KINDS array in your seeding service.
  # The default Rail behavior maps these to integer values (0, 1, 2, 3...)
  enum :business_type, { 
    full_time: 0, 
    part_time: 1, 
    contractor: 2, 
    intern: 3 
  }

  enum :status, { active: 0, archived: 1 }
  
  # --- Validations (Optional but recommended) ---
  validates :name, presence: true
  validates :business_type, presence: true

  has_many :employee_group_appointments, dependent: :destroy, as: :appoint_to
  has_many :employee_groups, through: :employee_group_appointments

  has_many :tag_appointments, dependent: :destroy, as: :appoint_to
  has_many :tags, through: :tag_appointments

  has_many :role_appointments, as: :appoint_to, dependent: :destroy
  has_many :roles, through: :role_appointments

end
