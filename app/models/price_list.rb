# frozen_string_literal: true

# PriceList — Atomic purpose: one named price book (retail, wholesale, contract) with the currency and customer group it applies to.
#
# Why it exists: B2B contract pricing cannot live on Product#price_cents: the same SKU sells at three prices depending on who buys it, and overwriting the catalog price per customer would destroy the retail price. A price book keeps each tier explicit and dated.
# How it works: header row only; lines live in PriceListItems with a min_quantity so volume breaks are rows, not formulas. `is_default` marks the fallback book when no group matches. Effective dates let a signed contract replace an older one without editing it.
# Main associations: belongs_to :company, :customer_group (optional); has_many :price_list_items.
class PriceList < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :customer_group, optional: true
  has_many :price_list_items, dependent: :destroy

  # --- Scopes ---
  scope :default_list, -> { where(is_default: true) }
  scope :active_on, ->(date = Date.current) {
    where("effective_from IS NULL OR effective_from <= ?", date)
      .where("effective_to IS NULL OR effective_to >= ?", date)
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :company_id }
end
