# frozen_string_literal: true

# StockCount — Atomic purpose: one stocktake event (full, cycle, spot or blind) for a warehouse.
#
# Why it exists: counting stock is a scheduled process with a start, a freeze and a reconciliation; without a header the individual counted lines have no shared context and variance cannot be reported per count, which is what shrinkage analysis needs.
# How it works: header holds the type, schedule and status; lines hold expected vs counted. A blind count hides expected values from the counter (FE decision), which is why the variance lives on the line rather than being computed only at the end. Corrections are applied through StockAdjustment, never by writing Stock directly.
# Main associations: belongs_to :company, :warehouse, :created_by_employee (optional); has_many :stock_count_lines.
class StockCount < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :count_type, STOCK_COUNT_TYPES, prefix: true, default: :cycle

  # --- Associations ---
  belongs_to :company
  belongs_to :warehouse
  belongs_to :created_by_employee, class_name: "Employee", optional: true
  has_many :stock_count_lines, dependent: :destroy

  # --- Scopes ---
  scope :open_counts, -> { where(status: [ :draft, :in_progress ]) }
  scope :recent_first, -> { order(created_at: :desc) }

  # --- Methods ---
  def variance_quantity
    stock_count_lines.sum(:variance_quantity)
  end
end
