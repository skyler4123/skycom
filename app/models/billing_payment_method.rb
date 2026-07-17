class BillingPaymentMethod < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country_code, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency_code, CURRENCIE_CODES, prefix: true, default: :usd

  encrypts :secret_key

  has_many :billing_transactions, dependent: :nullify

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    b2c: 0,
    b2b: 1
  }

  enum :payment_mode, {
    qr: 0,
    redirect: 1,
    cash: 2
  }

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: true
  validates :business_type, presence: true
  validates :payment_mode, presence: true
  validates :gateway_url, presence: true, unless: :cash_payment?

  def cash_payment?
    payment_mode == "cash"
  end
end
