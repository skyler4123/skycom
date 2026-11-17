# frozen_string_literal: true

# ProductBundleComponent — Atomic purpose: one component line of a product bundle and the quantity it consumes.
#
# Why it exists: the component list is the bill of materials for a retail kit; quantity per component is what turns one sale into several stock movements, and getting it wrong is a silent inventory drift.
# How it works: one row per (bundle, component). `is_optional` allows choice-based kits where only some components ship. Components may not be the bundle itself — validated to prevent a cycle at the atomic level.
# Main associations: belongs_to :company, :product_bundle, :component_product (Product).
class ProductBundleComponent < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :product_bundle
  belongs_to :component_product, class_name: "Product"

  # --- Validations ---
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :component_product_id, uniqueness: { scope: :product_bundle_id }
  validate :component_is_not_the_bundle

  private

  def component_is_not_the_bundle
    return if product_bundle.blank? || component_product_id != product_bundle.product_id

    errors.add(:component_product, "cannot be the bundle itself")
  end
end
