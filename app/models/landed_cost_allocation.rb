# frozen_string_literal: true

# LandedCostAllocation — Atomic purpose: the share of one landed cost charge attributed to one stock row.
#
# Why it exists: allocation must be recorded, not recomputed: if it were derived at report time, changing the allocation method would silently rewrite historical unit costs, and two reports run on different days would disagree.
# How it works: child of the charge, one row per contributed stock row, storing the quantity basis and the resulting cents. The sum of allocations must equal the charge amount — enforced by the generating service, checked here as a validation-friendly structure.
# Main associations: belongs_to :company, :landed_cost_charge, :stock, :product.
class LandedCostAllocation < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :landed_cost_charge
  belongs_to :stock
  belongs_to :product

  # --- Validations ---
  validates :allocated_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :stock_id, uniqueness: { scope: :landed_cost_charge_id }
end
