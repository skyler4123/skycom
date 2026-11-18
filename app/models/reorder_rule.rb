# frozen_string_literal: true

# ReorderRule — Atomic purpose: the minimum/maximum and lead time that decide when and how much of a product to reorder in a warehouse.
#
# Why it exists: replenishment is the difference between a stocked shelf and a stockout: the trigger (safety stock), the band (min/max) and how long a purchase takes (lead time) must be stated per product per warehouse, because the same SKU sells at ten times the rate in one branch.
# How it works: one row per (product, warehouse). `auto_action` decides whether a breach creates a purchase requisition, a transfer, or only a notification, so a rule can be advisory before it is automatic. Consumption velocity is not stored — it is computed from the ledger when generating a suggestion.
# Main associations: belongs_to :company, :product, :warehouse.
class ReorderRule < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :auto_action, REORDER_ACTIONS, prefix: true, default: :notify_only

  # --- Associations ---
  belongs_to :company
  belongs_to :product
  belongs_to :warehouse

  # --- Scopes ---
  scope :active, -> { where(is_active: true) }

  # --- Validations ---
  validates :min_quantity, :max_quantity, :safety_stock, :lead_time_days,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: { scope: :warehouse_id }

  # --- Methods ---
  def below_trigger?(available_quantity)
    available_quantity.to_i <= (min_quantity.to_i + safety_stock.to_i)
  end

  def suggested_quantity(available_quantity)
    [ max_quantity.to_i - available_quantity.to_i, 0 ].max
  end
end
