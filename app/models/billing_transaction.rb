# frozen_string_literal: true

# A record of a money movement belonging to a BillingInvoice.
# Every balance change goes through a BillingTransaction — it is the
# source of truth for all money movements in Skycom.
#
# Created by:
#   - Billing::SettlementService (monthly billing deductions)
#   - Top-ups / promo credits (deposits into company wallet)
#   - Seed::BillingDataService (historical seeding)
#
# The invoice's payment_status is derived from the sum of its transactions:
#   SUM(transactions.amount_cents) >= invoice.price_cents  →  paid
#
class BillingTransaction < ApplicationRecord
  attribute :amount_cents, :integer, default: 0
  attribute :currency, :string, default: "USD"
  attribute :balance_before_cents, :integer, default: 0
  attribute :balance_after_cents, :integer, default: 0
  attribute :promo_balance_before_cents, :integer, default: 0
  attribute :promo_balance_after_cents, :integer, default: 0

  belongs_to :company
  belongs_to :billing_invoice

  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :billing_invoice, presence: true

  enum :transaction_type, {
    top_up: 0,
    deduction: 1,
    refund: 2,
    promo_credit: 3
  }

  after_create :sync_invoice_payment_status, unless: -> { amount_cents.zero? }
  after_destroy :sync_invoice_payment_status

  private

  def sync_invoice_payment_status
    total = billing_invoice.billing_transactions.sum(:amount_cents)
    new_status = total >= billing_invoice.price_cents ? :paid : :unpaid
    return if billing_invoice.payment_status == new_status.to_s

    billing_invoice.update!(payment_status: new_status)
  end
end
