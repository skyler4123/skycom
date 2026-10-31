# frozen_string_literal: true

# CompanyWallet — Atomic purpose: store the credit balance NUMBERS only.
#
# Why it exists: one lockable row serializes every balance mutation under
# with_lock (row-level FOR UPDATE) without manual version bookkeeping. Balances
# may go negative when a deduction exceeds the available credit; there is no
# separate debt balance.
# How it works: credit IN flows through the chain
# (CompanyTransaction → CompanyInvoice → CompanyOrder → CompanyWallet) and promo
# grants. Credit OUT is CONTROLLER-ONLY via CompanyCreditDeduction::* — never
# from a background job, import, seed, or migration. Background jobs are
# free-credit: they may grant credits and drain usage counters, but must never
# call deduct_from! or CompanyCreditDeduction::*.
# Balances: main — real purchased credits (top-ups land here via add_credits!);
# promo — promotional credits (deducted FIRST by CompanyCreditDeduction::*).
# Main associations: belongs_to :company, :walletable (polymorphic, required);
# has_many :company_wallet_logs, :company_usage_logs (dependent: :destroy).
class CompanyWallet < ApplicationRecord
  USAGE_LOGGING_WINDOW = 5.minutes

  # Single-file constant: map balance key → column name.
  BALANCES = {
    main: "main_credit_balance",
    promo: "promo_credit_balance"
  }.freeze

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true, default: :active
  enum :workflow_status, WORKFLOW_STATUS, prefix: true, default: :confirmed
  belongs_to :company
  belongs_to :walletable, polymorphic: true
  has_many :company_wallet_logs, dependent: :destroy
  has_many :company_usage_logs, dependent: :destroy

  # Top-up entry point (used by the credit-purchase chain via CompanyOrder#complete!).
  # Always lands on the MAIN balance — promotional credits are granted separately.

  def add_credits!(amount:, source: nil, description: nil, action_type: "top_up")
    add_to!(balance: :main, amount: amount, source: source, description: description, action_type: action_type)
  end

  # Low-level atomic mutation entry points.
  # add_to! / add_credits! are allowed from controllers, background jobs (promo
  # grants, top-up completion), and seeds. deduct_from! is CONTROLLER-ONLY via
  # CompanyCreditDeduction::* — background jobs are free-credit and must never
  # take credits out of a wallet.

  def add_to!(balance:, amount:, source: nil, description: nil, action_type: "top_up")
    column = balance_column!(balance)
    raise ArgumentError, "amount must be a positive integer" unless amount.is_a?(Integer) && amount.positive?

    with_lock do
      before = public_send(column)
      update_columns(column => public_send(column) + amount)
      CompanyWalletLog.create!(
        company: company, company_wallet: self, change_type: :credit,
        change_amount: amount, balance_before: before, balance_after: public_send(column),
        balance_type: balance, source: source, description: description
      )
      record_usage_log!(action_type: action_type, source: source, change_amount: amount, description: description)
      company.sync_credit_status!(total_credit_balance: total_credit_balance)
    end
    public_send(column)
  end

  def deduct_from!(balance:, amount:, source: nil, description: nil, action_type: "deduction")
    column = balance_column!(balance)
    raise ArgumentError, "amount must be a positive integer" unless amount.is_a?(Integer) && amount.positive?

    with_lock do
      current = public_send(column)
      update_columns(column => current - amount)
      CompanyWalletLog.create!(
        company: company, company_wallet: self, change_type: :debit,
        change_amount: -amount, balance_before: current, balance_after: public_send(column),
        balance_type: balance, source: source, description: description
      )
      record_usage_log!(action_type: action_type, source: source, change_amount: -amount, description: description)
      company.sync_credit_status!(total_credit_balance: total_credit_balance)
    end
    public_send(column)
  end

  def usage_logging_active?
    usage_logging_until.present? && usage_logging_until > Time.current
  end

  # Usable balance = purchased + promotional credits. May be negative when a
  # deduction exceeded the available credit.
  def total_credit_balance
    main_credit_balance + promo_credit_balance
  end

  def enable_usage_logging!(window: USAGE_LOGGING_WINDOW)
    update!(usage_logging_until: Time.current + window)
  end

  def disable_usage_logging!
    update!(usage_logging_until: nil)
  end

  private

  def balance_column!(balance)
    column = BALANCES[balance.to_sym]
    raise ArgumentError, "unknown balance: #{balance}" unless column

    column
  end

  def record_usage_log!(action_type:, source:, change_amount:, description:)
    return unless usage_logging_active?

    CompanyUsageLog.create!(
      company: company, company_wallet: self,
      action_type: action_type, change_amount: change_amount,
      balance_after: total_credit_balance, source: source, description: description
    )
  end
end
