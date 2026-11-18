# frozen_string_literal: true

# PurchaseMatchAppointment — Atomic purpose: one three-way-match row tying a purchase order, its goods receipt and the vendor bill that charges for it.
#
# Why it exists: paying a vendor bill without proving the goods arrived at the agreed price is how duplicate and inflated invoices get paid. The match needs three concrete references plus the matched quantity and amount, which cannot be expressed by tagging rows.
# How it works: PO side is `purchase`; the vendor bill is `related_purchase`; the goods receipt is `stock_import`. Any side may be null while the match is partial, and `status` records unmatched/partial/matched/disputed. Amounts are integer cents so tolerance rules compare exactly.
# Main associations: belongs_to :company, :purchase, :related_purchase (Purchase, optional), :stock_import (optional).
class PurchaseMatchAppointment < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, PURCHASE_MATCH_STATUSES, prefix: true, default: :unmatched

  # --- Associations ---
  belongs_to :company
  belongs_to :purchase
  belongs_to :related_purchase, class_name: "Purchase", optional: true
  belongs_to :stock_import, optional: true

  # --- Validations ---
  validates :matched_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :matched_amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
