# frozen_string_literal: true

# ProductBarcode — Atomic purpose: one scannable code (EAN/UPC/internal) mapped to a product and a pack quantity.
#
# Why it exists: the entire warehouse and POS scanning feature depends on turning a scanned string into a product; products have no barcode column, and a product legitimately has several codes (case of 12 vs single unit). A row per code is the only shape that holds both.
# How it works: codes are company-unique because two tenants may sell the same manufacturer EAN. `pack_quantity` lets one scan mean twelve units. `is_primary` marks the code printed on labels while secondary codes stay scannable.
# Main associations: belongs_to :company, :product.
class ProductBarcode < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :product

  # --- Scopes ---
  scope :primary, -> { where(is_primary: true) }

  # --- Validations ---
  validates :barcode, presence: true, length: { maximum: 128 }, uniqueness: { scope: :company_id }
  validates :pack_quantity, numericality: { only_integer: true, greater_than: 0 }
end
