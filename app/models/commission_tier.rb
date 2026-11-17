# frozen_string_literal: true

# CommissionTier — Atomic purpose: one commission bracket (from amount, to amount, rate) inside a plan.
#
# Why it exists: tiered commission — 2% up to 100M, 5% above — is the normal arrangement; encoding it as rows keeps the breakpoints editable and the payout mathematically reproducible without code changes.
# How it works: rate is basis points so no float touches money. Bounds are integer cents, inclusive lower and exclusive upper, with the last tier open-ended. Unique per (plan, from_cents).
# Main associations: belongs_to :company, :commission_plan.
class CommissionTier < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :commission_plan

  # --- Scopes ---
  scope :ordered, -> { order(:from_cents) }

  # --- Validations ---
  validates :from_cents, :rate_bp, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :to_cents, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :to_greater_than_from

  # --- Methods ---
  def covers_cents?(amount_cents)
    return false if amount_cents.to_i < from_cents.to_i

    to_cents.nil? || amount_cents.to_i < to_cents.to_i
  end

  private

  def to_greater_than_from
    return if to_cents.blank? || to_cents > from_cents

    errors.add(:to_cents, "must be greater than the lower bound")
  end
end
