# frozen_string_literal: true

# MaintenancePlan — Atomic purpose: a recurring preventive maintenance rule for one facility or fixed asset.
#
# Why it exists: equipment is maintained on a schedule, not when it breaks: the interval and the next due date are the whole feature, and keeping them on the machine is what lets a job generate the next visit instead of a person remembering.
# How it works: interval by calendar days or by usage units (machine hours), whichever the equipment needs. `next_due_on` is the single source of truth for the job; `last_done_on` records the last completed visit. Checks are MaintenanceChecks so a plan carries its own checklist.
# Main associations: belongs_to :company, :facility (optional), :fixed_asset (optional); has_many :maintenance_checks.
class MaintenancePlan < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :facility, optional: true
  belongs_to :fixed_asset, optional: true
  has_many :maintenance_checks, dependent: :destroy

  # --- Scopes ---
  scope :due, ->(date = Date.current) { where(next_due_on: ..date) }
  scope :active, -> { where(status: :confirmed) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validate :has_a_trigger

  # --- Methods ---
  def due?(date = Date.current)
    next_due_on.present? && next_due_on <= date
  end

  private

  def has_a_trigger
    return if interval_days.present? || interval_usage.present?

    errors.add(:base, "requires an interval in days or in usage units")
  end
end
