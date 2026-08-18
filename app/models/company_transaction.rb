# frozen_string_literal: true

# CompanyTransaction — Atomic purpose: record money movement for a
# CompanyInvoice (the chain's entry point and gateway interface). On create/
# destroy it DERIVES the invoice's payment_status from the sum of its
# completed payment transactions. This is a rare money event — the only
# callbacks in the credit system.
class CompanyTransaction < ApplicationRecord
  store_accessor :metadata, :gateway_payload

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :company_invoice
  belongs_to :billing_payment_method

  enum :transaction_type, { payment: 0, refund: 1 }, default: :payment
  enum :status, { pending: 0, completed: 1, failed: 2 }, default: :pending
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true, default: :active
  enum :workflow_status, WORKFLOW_STATUS, prefix: true, default: :confirmed

  validates :money_amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :gateway_reference, uniqueness: true, allow_nil: true

  after_create :sync_invoice_payment_status, if: :completed?
  after_update :sync_invoice_payment_status, if: :completed?
  after_destroy :sync_invoice_payment_status

  private

  def sync_invoice_payment_status
    total = company_invoice.company_transactions
      .where(transaction_type: :payment, status: :completed)
      .sum(:money_amount_cents)
    new_status = total >= company_invoice.money_amount_cents ? :paid : :unpaid
    return if company_invoice.payment_status == new_status.to_s

    company_invoice.update!(payment_status: new_status)
  end
end
