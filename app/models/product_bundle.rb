# frozen_string_literal: true

# ProductBundle — Atomic purpose: declares that one sellable product is assembled from other products (a kit or bundle).
#
# Why it exists: selling a gift set or a starter kit must decrement three SKUs while selling one line item; without an explicit bundle definition the warehouse either ships the wrong goods or the stock ledger lies.
# How it works: the bundle is itself a Product (so it can be priced, taxed and sold like any other); this row marks it as composite and components live in ProductBundleComponents. Assembly and disassembly are stock movements, not edits here.
# Main associations: belongs_to :company, :product; has_many :product_bundle_components.
class ProductBundle < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :product
  has_many :product_bundle_components, dependent: :destroy

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }

  # --- Validations ---
  validates :product_id, uniqueness: { scope: :company_id }
end
