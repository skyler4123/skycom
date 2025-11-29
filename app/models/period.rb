class Period < ApplicationRecord
  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true

  has_one :period_appointment, as: :appoint_to, dependent: :destroy
  has_one :booking, through: :period_appointment

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :start_at, presence: true
  validates :end_at, presence: true

  # Custom validation to ensure end_at is after start_at
  validate :end_at_after_start_at

  private

  def end_at_after_start_at
    return if end_at.blank? || start_at.blank?

    errors.add(:end_at, "must be after the start date") if end_at < start_at
  end
end