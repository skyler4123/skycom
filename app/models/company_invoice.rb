# frozen_string_literal: true

# CompanyInvoice — Atomic purpose: the bill for a credit purchase. payment_status
# is DERIVED from the sum of its CompanyTransactions (never set directly by
# business code — only the sync callback in CompanyTransaction writes it). When
# the invoice becomes paid it completes its CompanyOrder, which credits the wallet.
class CompanyInvoice < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :company_order, optional: true
  has_many :company_transactions, dependent: :destroy

  enum :payment_status, { unpaid: 0, paid: 1, overdue: 2, refunded: 3 }, default: :unpaid
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true, default: :active
  enum :workflow_status, WORKFLOW_STATUS, prefix: true, default: :confirmed

  validates :invoice_number, presence: true, uniqueness: true
  validates :money_amount_cents, :credit_amount,
    presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :unpaid, -> { where(payment_status: :unpaid) }
  scope :paid, -> { where(payment_status: :paid) }

  before_validation :generate_invoice_number, on: :create
  after_update :complete_order_if_paid!, if: -> { saved_change_to_payment_status? && paid? }

  private

  def complete_order_if_paid!
    company_order&.complete!
  end

  def generate_invoice_number
    return if invoice_number.present?

    date_slug = Time.current.strftime("%Y%m")
    random_slug = SecureRandom.hex(3).upcase
    self.invoice_number = "INV-#{date_slug}-#{random_slug}"
  end
end
