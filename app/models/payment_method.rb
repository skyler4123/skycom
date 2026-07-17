class PaymentMethod < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # 🚀 SECURITY ENHANCEMENT: Automatically encrypts the secret_key in the database.
  # It safely decrypts on-the-fly when read in your backend controller code.
  encrypts :secret_key

  # --- Associations ---
  # This model is intended to be global, so it does not belong to a branch.
  has_many :payment_method_appointments, dependent: :destroy
  has_many :branches, through: :payment_method_appointments
  has_many :transactions, dependent: :nullify

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    b2c: 0,
    b2b: 1
  }

  # 🚀 NEW ENUM: Maps integers in your database to distinct frontend interface actions
  enum :payment_mode, {
    qr: 0,          # Frontend: Render image via your JS helper
    redirect: 1, # Frontend: Hop window to the provider page
    cash: 2          # Frontend: Display manual receipt instructions
  }

  # --- Strategy ---
  enum :strategy, GATEWAY_STRATEGIES, prefix: true

  # --- Validations ---
  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: true
  validates :business_type, presence: true


  # 🚀 NEW VALIDATIONS: Ensure online gateways always possess their routing targets
  validates :payment_mode, presence: true
  validates :strategy, presence: true, unless: :system_payment?
  validates :gateway_url, presence: true, unless: :system_payment?

  def cash_payment?
    strategy_cash?
  end

  def system_payment?
    strategy_cash? || strategy_wallet_auto_debit?
  end
end
