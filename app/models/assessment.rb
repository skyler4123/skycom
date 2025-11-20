class Assessment < ApplicationRecord
  # --- Associations ---
  belongs_to :company

  # --- Enums ---
  enum :status, {
    draft: 0,
    published: 1,
    archived: 2
  }

  enum :business_type, {
    performance_review: 0,
    skill_gap_analysis: 1,
    compliance_check: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :status, presence: true
  validates :business_type, presence: true
end