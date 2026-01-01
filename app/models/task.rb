class Task < ApplicationRecord
  include TagConcern

  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  belongs_to :task_group

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  enum :business_type, {
    general: 0,
    technical: 1,
    administrative: 2
  }

  enum :currency, {
    usd: 0,
    eur: 1,
    gbp: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }

  validates :business_type, presence: true
end
