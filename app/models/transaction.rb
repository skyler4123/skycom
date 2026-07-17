class Transaction < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern

  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :amount_cents, :integer, default: 0

  enum :country_code, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency_code, CURRENCIE_CODES, prefix: true, default: :usd

  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :invoice
  belongs_to :category
  belongs_to :property_mapping
  belongs_to :payment_method, optional: true

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    standard_payment: 0,
    prepayment: 1,
    final_payment: 2
  }

  enum :payment_status, { unpaid: 0, paid: 1, voided: 2 }, default: :unpaid

  validates :currency_code, presence: true

  after_create :sync_invoice_payment_status, unless: -> { amount_cents.zero? }
  after_destroy :sync_invoice_payment_status

  private

  def sync_invoice_payment_status
    total = invoice.transactions.sum(:amount_cents)
    new_status = total >= invoice.total_price_cents ? :paid : :unpaid
    return if invoice.payment_status == new_status.to_s
    invoice.update!(payment_status: new_status)
  end
end
