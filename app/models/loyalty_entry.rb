# frozen_string_literal: true

# LoyaltyEntry — Atomic purpose: one immutable points movement (earn, redeem, expire, manual adjust) for a customer.
#
# Why it exists: a points balance must be auditable: every card balance has to be explainable as a list of movements, otherwise a disputed redemption cannot be settled and expiry quietly destroys value nobody can trace.
# How it works: append-only, signed by `direction`, never updated. `source_type`/`source_id` points at the order or campaign that caused the movement using the same polymorphic convention as the stock and workflow logs. Balance is the sum of entries, never a stored counter.
# Main associations: belongs_to :company, :customer, :loyalty_program, :source (polymorphic, optional).
class LoyaltyEntry < ApplicationRecord
  # --- Enums ---
  enum :direction, LOYALTY_DIRECTIONS, prefix: true, default: :earn

  # --- Associations ---
  belongs_to :company
  belongs_to :customer
  belongs_to :loyalty_program
  belongs_to :source, polymorphic: true, optional: true

  # --- Scopes ---
  scope :unexpired, ->(date = Date.current) { where("expires_on IS NULL OR expires_on >= ?", date) }

  # --- Validations ---
  validates :points, numericality: { only_integer: true }
end
