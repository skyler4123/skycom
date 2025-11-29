class Task < ApplicationRecord
  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  belongs_to :task_group

  # --- Enums ---
  enum :status, {
    to_do: 0,
    in_progress: 1,
    done: 2,
    archived: 3
  }

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
  validates :status, presence: true
  validates :business_type, presence: true
end
