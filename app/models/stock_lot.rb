# frozen_string_literal: true

# StockLot — Atomic purpose: one received batch/lot of a product, with its expiry and supplier, for traceability.
#
# Why it exists: recalls, warranties and FEFO picking all need 'which batch did this come from'. Once goods are mixed in a single warehouse quantity there is no way to trace a defective batch back to the customers who received it.
# How it works: no quantity column on purpose: quantities stay in stock_transactions (which gains stock_lot_id), so the ledger remains the only place a number lives. `expires_on` drives FEFO ordering and expiry alerts. Status quarantines a lot without deleting its history.
# Main associations: belongs_to :company, :product, :warehouse, :supplier (optional); has_many :stock_transactions, :stock_serials.
class StockLot < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, STOCK_LOT_STATUSES, prefix: true, default: :open

  # --- Associations ---
  belongs_to :company
  belongs_to :product
  belongs_to :warehouse
  belongs_to :supplier, optional: true
  has_many :stock_serials, dependent: :nullify
  has_many :stock_transactions, dependent: :restrict_with_error

  # --- Scopes ---
  scope :expiring_before, ->(date) { where.not(expires_on: nil).where(expires_on: ..date) }
  scope :fefo, -> { order(Arel.sql("expires_on ASC NULLS LAST")) }
  scope :usable, -> { where(status: [ :open ]) }

  # --- Validations ---
  validates :lot_code, presence: true, length: { maximum: 64 }
  validates :lot_code, uniqueness: { scope: [ :company_id, :product_id, :warehouse_id ] }

  # --- Methods ---
  def expired?
    expires_on.present? && expires_on < Date.current
  end
end
