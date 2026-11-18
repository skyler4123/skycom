# frozen_string_literal: true

# StockSerial — Atomic purpose: one individually tracked unit (serial number / IMEI) and where it currently is.
#
# Why it exists: high-value and warranty goods are tracked per unit, not per batch: a customer brings back a serial, and the company must answer when it was sold, to whom, and whether it is still under warranty. Serial numbers are also the evidence for a warranty claim.
# How it works: one row per unit, lifecycle from in_stock to sold/returned/scrapped. `sold_order_id` and `warranty_until` answer the after-sales questions. Current location is denormalised here because a serial has exactly one place; the movement history stays in stock_transactions.
# Main associations: belongs_to :company, :stock, :stock_lot (optional), :storage_location (optional), :sold_order (Order, optional).
class StockSerial < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, SERIAL_STATUSES, prefix: true, default: :in_stock

  # --- Associations ---
  belongs_to :company
  belongs_to :stock
  belongs_to :stock_lot, optional: true
  belongs_to :storage_location, optional: true
  belongs_to :sold_order, class_name: "Order", optional: true

  # --- Scopes ---
  scope :in_stock, -> { where(status: :in_stock) }
  scope :sold, -> { where(status: :sold) }

  # --- Validations ---
  validates :serial_number, presence: true, length: { maximum: 128 }, uniqueness: { scope: :company_id }

  # --- Methods ---
  def under_warranty?
    warranty_until.present? && warranty_until >= Date.current
  end
end
