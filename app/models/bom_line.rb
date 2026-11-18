# frozen_string_literal: true

# BomLine — Atomic purpose: one component of a bill of materials with the quantity and expected scrap it consumes.
#
# Why it exists: material requirements are the sum of component lines scaled by production quantity; a scrap percentage is what stops MRP from ordering exactly enough and then running short on every real run.
# How it works: ordered child rows with `component_product` and a per-line scrap rate in basis points, so 2.5% is expressible without floats in money paths. Position keeps the recipe readable and stable across versions.
# Main associations: belongs_to :company, :bill_of_material, :component_product (Product).
class BomLine < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :bill_of_material
  belongs_to :component_product, class_name: "Product"

  # --- Scopes ---
  scope :ordered, -> { order(:position) }

  # --- Validations ---
  validates :quantity, numericality: { greater_than: 0 }
  validates :scrap_bp, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :position, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :bill_of_material_id }

  # --- Methods ---
  def required_quantity_for(run_quantity)
    quantity.to_d * run_quantity.to_d * (1 + scrap_bp.to_i / 10_000.0)
  end
end
