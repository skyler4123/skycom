class PaymentMethod < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Specific Real-World Lifecycle Map ---
  LIFECYCLE_STATUSES = {
    draft: 0,       # Initial creation phase; missing gateway parameters or branch assignment
    active: 1,      # Live and available at POS / Checkout interfaces
    maintenance: 2, # Temporarily unavailable (e.g., provider gateway maintenance)
    disabled: 3,    # Toggled off by store admin; hidden from POS / Checkout selections
    deprecated: 4,  # Phased out; visible only for pending refunds/reconciliations
    archived: 5     # Soft-deleted/retired; retained solely for financial record compliance
  }.freeze

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Associations ---
  has_many :payment_method_appointments, dependent: :destroy
  has_many :branches, through: :payment_method_appointments
  has_many :transactions, dependent: :nullify

  # --- Enums ---
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

  # --- Validations ---
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
