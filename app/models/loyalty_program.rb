# frozen_string_literal: true

# LoyaltyProgram — Atomic purpose: the earning and redemption rules of one customer loyalty scheme.
#
# Why it exists: points are a liability like store credit: the rate they accrue at, the rate they redeem at and when they expire must be stated once, or the balance on a customer card cannot be reconciled to anything.
# How it works: rates are basis points so earning 1 point per 100 spent is expressible exactly. Expiry is a day count, applied by a job that writes expiring entries rather than deleting points. Multiple programs per company are allowed (retail vs online).
# Main associations: belongs_to :company; has_many :loyalty_entries.
class LoyaltyProgram < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  has_many :loyalty_entries, dependent: :restrict_with_error

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :company_id }
  validates :earn_rate_bp, :redeem_rate_bp, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
