class BillingPaymentMethod < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Specific Real-World Lifecycle Map ---
  LIFECYCLE_STATUSES = {
    draft: 0,       # Initial creation phase; waiting for provider API keys or webhook secrets
    active: 1,      # Healthy and processing billing transactions live
    maintenance: 2, # Temporarily offline (e.g., bank gateway downtime, key rotation)
    disabled: 3,    # Soft-disabled manually; no transactions permitted until turned back on
    deprecated: 4,  # End-of-life status; blocked for new invoices, allows pending settlement
    archived: 5     # Permanently retired for accounting audit compliance
  }.freeze

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  has_many :billing_transactions, dependent: :nullify

  # --- Lifecycle Enum with Real-Life Map ---
  enum :lifecycle_status, LIFECYCLE_STATUSES, prefix: true, default: :draft
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    b2c: 0,
    b2b: 1
  }

  enum :payment_mode, {
    qr: 0,          # Frontend: Render dynamic/static QR code
    redirect: 1,    # Frontend: Redirect window to hosted provider page
    cash: 2         # Frontend: Display manual drawer / receipt instructions
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
