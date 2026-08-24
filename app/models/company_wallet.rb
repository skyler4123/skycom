# frozen_string_literal: true

# CompanyWallet — Atomic purpose: store the credit balance NUMBERS only.
# No business logic. Balance changes flow exclusively through the chain
# (CompanyTransaction → CompanyInvoice → CompanyOrder → CompanyWallet) and
# through the CompanyCreditDeduction::* services; the wallet exposes only low-level per-balance
# mutation entry points (add_to! / deduct_from!).
#
# Balances:
#   main  — real purchased credits (top-ups land here via add_credits!)
#   promo — promotional credits (deducted FIRST by CompanyCreditDeduction::* services)
#   debt  — absorbed shortfall when promo + main are exhausted (normally 0)
#
# Atomicity: every mutation runs inside with_lock (transaction + row-level
# FOR UPDATE), so concurrent operations serialize on the wallet row and can
# never overdraw — Rails' own locking, no manual version bookkeeping.
class CompanyWallet < ApplicationRecord
  USAGE_LOGGING_WINDOW = 5.minutes

  # Single-file constant: map balance key → column name.
  BALANCES = {
    main: "main_credit_balance",
    promo: "promo_credit_balance",
    debt: "debt_credit_balance"
  }.freeze

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true, default: :active
  enum :workflow_status, WORKFLOW_STATUS, prefix: true, default: :confirmed
  belongs_to :company
  belongs_to :walletable, polymorphic: true
  has_many :company_wallet_logs, dependent: :destroy
  has_many :company_usage_logs, dependent: :destroy

  class InsufficientCreditsError < StandardError; end

  # Top-up entry point (used by the credit-purchase chain via CompanyOrder#complete!).
  # Always lands on the MAIN balance — promotional credits are granted separately.

  def add_credits!(amount:, source: nil, description: nil, action_type: "top_up")
    add_to!(balance: :main, amount: amount, source: source, description: description, action_type: action_type)
  end

  # Low-level atomic mutation entry points — called by CompanyCreditDeduction::* services.

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
    end
    public_send(column)
  end

  def deduct_from!(balance:, amount:, source: nil, description: nil, action_type: "deduction")
    column = balance_column!(balance)
    raise ArgumentError, "amount must be a positive integer" unless amount.is_a?(Integer) && amount.positive?

    with_lock do
      current = public_send(column)
      raise InsufficientCreditsError, "Insufficient credits (balance: #{current}, required: #{amount})" if current < amount

      update_columns(column => current - amount)
      CompanyWalletLog.create!(
        company: company, company_wallet: self, change_type: :debit,
        change_amount: -amount, balance_before: current, balance_after: public_send(column),
        balance_type: balance, source: source, description: description
      )
      record_usage_log!(action_type: action_type, source: source, change_amount: -amount, description: description)
    end
    public_send(column)
  end

  def usage_logging_active?
    usage_logging_until.present? && usage_logging_until > Time.current
  end

  # Usable balance = purchased + promotional credits (debt is not spendable).
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
