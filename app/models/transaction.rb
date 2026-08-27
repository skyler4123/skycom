# TODO: Unify transaction_token / gateway_reference naming — column is gateway_reference
# but API/service layer exposes transaction_token (pay response, pay_cancel, Initiate/Cancel services).
# Pick one canonical name and migrate the other.
class Transaction < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern

  include TagConcern
  attribute :permission_resource_name, :string, default: -> { self.name }
  attribute :price_cents, :integer, default: 0
  store_accessor :metadata, :gateway_payload

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :status, { pending: 0, completed: 1, failed: 2 }, default: :pending
  enum :business_type, {
    standard_payment: 0,
    prepayment: 1,
    final_payment: 2
  }
  enum :payment_status, { unpaid: 0, paid: 1, voided: 2 }, default: :unpaid
  monetize :price_cents,
           as: "price",
           with_model_currency: :currency,
           disable_validation: true

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :invoice
  belongs_to :category
  belongs_to :property_mapping
  belongs_to :payment_method, optional: true

  validates :currency, presence: true
  validates :gateway_reference, uniqueness: true, allow_nil: true

  after_create :sync_invoice_payment_status, if: -> { completed? && !price_cents.zero? }
  after_update :sync_invoice_payment_status, if: :completed?
  after_destroy :sync_invoice_payment_status

  private

  def sync_invoice_payment_status
    total = invoice.transactions.sum(:price_cents)
    new_status = total >= invoice.price_cents ? :paid : :unpaid
    return if invoice.payment_status == new_status.to_s
    invoice.update!(payment_status: new_status)
  end
end
