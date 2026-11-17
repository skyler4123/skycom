# frozen_string_literal: true

# SubcontractOrder — Atomic purpose: one job sending materials to a third-party processor and receiving finished goods back.
#
# Why it exists: outsourced processing moves inventory the company still owns; without a row tracking what was sent and what came back, those materials vanish from accountability the moment they leave the gate.
# How it works: links the supplier and, when the work is procured, the purchase document. Sent/received quantities are kept separately because partial returns are normal. Status distinguishes sent from partially received, and the stock movements themselves still go through the ledger.
# Main associations: belongs_to :company, :supplier, :purchase (optional), :product.
class SubcontractOrder < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, SUBCONTRACT_STATUSES, prefix: true, default: :draft

  # --- Associations ---
  belongs_to :company
  belongs_to :supplier
  belongs_to :purchase, optional: true
  belongs_to :product

  # --- Scopes ---
  scope :open_orders, -> { where(status: [ :draft, :sent, :partially_received ]) }

  # --- Validations ---
  validates :quantity, numericality: { greater_than: 0 }
end
