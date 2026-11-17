# frozen_string_literal: true

# ProductionOrderMaterial — Atomic purpose: one component line of a production order: how much is required and how much has actually been consumed.
#
# Why it exists: material variance is the difference between what the recipe said and what the floor used; both numbers must be stored per line, per order, or over-consumption can only be discovered by counting the warehouse at month end.
# How it works: required quantity is snapshotted from the BOM at release; consumed is written as material is issued (through the stock ledger). `stock_lot` records which batch was consumed for traceability. Editing the BOM afterwards cannot change either number.
# Main associations: belongs_to :company, :production_order, :product, :stock_lot (optional).
class ProductionOrderMaterial < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :production_order
  belongs_to :product
  belongs_to :stock_lot, optional: true

  # --- Validations ---
  validates :required_quantity, :consumed_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: { scope: :production_order_id }

  # --- Methods ---
  def variance_quantity
    consumed_quantity.to_d - required_quantity.to_d
  end
end
