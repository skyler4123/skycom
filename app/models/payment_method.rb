# frozen_string_literal: true

# PaymentMethod — Atomic purpose: global gateway/payment catalog entry (QR,
# redirect, cash, wallet) defined by the platform.
#
# Why it exists: one definition per gateway strategy, shared by every tenant;
# company/branch scoping and merchant credentials live on the appointment rows,
# not here (see docs/PAYMENT_METHODS.md).
# How it works: has_many company/branch payment method appointments and
# transactions (nullify). system_payment? covers cash and wallet auto-debit
# strategies; strategy is required for external gateways.
# Main associations: has_many :company_payment_method_appointments,
# :branch_payment_method_appointments (dependent: :destroy); has_many :companies,
# :branches through them; has_many :transactions (dependent: :nullify).
class PaymentMethod < ApplicationRecord
  # --- Specific Real-World Lifecycle Map ---
  LIFECYCLE_STATUSES = {
    draft: 0,       # Initial creation phase; missing gateway parameters or branch assignment
    active: 1,      # Live and available at POS / Checkout interfaces
    maintenance: 2, # Temporarily unavailable (e.g., provider gateway maintenance)
    disabled: 3,    # Toggled off by store admin; hidden from POS / Checkout selections
    deprecated: 4,  # Phased out; visible only for pending refunds/reconciliations
    archived: 5     # Soft-deleted/retired; retained solely for financial record compliance
  }.freeze
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

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
  # --- Associations ---
  has_many :company_payment_method_appointments, dependent: :destroy
  has_many :companies, through: :company_payment_method_appointments
  has_many :branch_payment_method_appointments, dependent: :destroy
  has_many :branches, through: :branch_payment_method_appointments

  has_many :transactions, dependent: :nullify

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
