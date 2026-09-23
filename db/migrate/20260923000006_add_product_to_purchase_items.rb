class AddProductToPurchaseItems < ActiveRecord::Migration[8.0]
  def change
    # The Purchase ↔ Stock bridge (docs/superpowers/specs/2026-09-23-stock-source-of-truth-design.md §4):
    # a purchase item may reference a catalog Product — when it does, purchase
    # completion imports units of that product into the destination warehouse.
    # Optional: non-stocked purchases (office supplies, services) stay product-less.
    add_reference :purchase_items, :product, foreign_key: true, type: :uuid
  end
end
