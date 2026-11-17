# frozen_string_literal: true

# LandedCostCharge — Atomic purpose: one non-material cost (freight, duty, insurance, handling) attached to a goods receipt.
#
# Why it exists: true product margin is cost of goods plus the cost of getting them in; if freight and duty are booked as generic expenses, every unit cost is understated and the product looks more profitable than it is. A charge row is what makes allocation to units possible.
# How it works: one row per charge type on a stock import, with the allocation method chosen per charge (by quantity, value, weight or equal). LandedCostAllocations store the resulting per-stock split so the distribution is auditable and does not have to be recomputed.
# Main associations: belongs_to :company, :stock_import, :supplier (optional); has_many :landed_cost_allocations.
class LandedCostCharge < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :charge_type, LANDED_COST_CHARGE_TYPES, prefix: true, default: :freight
  enum :allocation_method, ALLOCATION_METHODS, prefix: true, default: :by_value

  # --- Associations ---
  belongs_to :company
  belongs_to :stock_import
  belongs_to :supplier, optional: true
  has_many :landed_cost_allocations, dependent: :destroy

  # --- Validations ---
  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
