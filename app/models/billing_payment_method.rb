class BillingPaymentMethod < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

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

  enum :strategy, GATEWAY_STRATEGIES, prefix: true

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: true
  validates :business_type, presence: true
  validates :payment_mode, presence: true
  validates :strategy, presence: true, unless: :system_payment?

  def cash_payment?
    strategy_cash?
  end

  def system_payment?
    strategy_cash? || strategy_wallet_auto_debit?
  end
end
