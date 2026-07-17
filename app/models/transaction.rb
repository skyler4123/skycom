class Transaction < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern

  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :price_cents, :integer, default: 0

  monetize :price_cents,
           as: "price",
           with_model_currency: :currency,
           disable_validation: true

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

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

  validates :currency, presence: true

  after_create :sync_invoice_payment_status, unless: -> { price_cents.zero? }
  after_destroy :sync_invoice_payment_status

  private

  def sync_invoice_payment_status
    total = invoice.transactions.sum(:price_cents)
    new_status = total >= invoice.price_cents ? :paid : :unpaid
    return if invoice.payment_status == new_status.to_s
    invoice.update!(payment_status: new_status)
  end
end
