class BillingInvoice < ApplicationRecord
  belongs_to :company
  belongs_to :billing_contract
  has_many :wallet_transactions # To track exactly which wallet payment cleared this bill

  validates :invoice_number, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum :payment_status, { unpaid: 0, paid: 1, voided: 2, overdue: 3 }, default: :unpaid
  enum :lifecycle_status, { final: 0, draft: 1 }, default: :final

  before_validation :generate_invoice_number, on: :create

  private

  def generate_invoice_number
    return if invoice_number.present?
    
    # Creates a clean searchable string like INV-202606-XXXXXX
    date_slug = Time.current.strftime("%Y%m")
    random_slug = SecureRandom.hex(3).upcase
    self.invoice_number = "INV-#{date_slug}-#{random_slug}"
  end
end