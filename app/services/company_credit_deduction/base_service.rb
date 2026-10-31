# frozen_string_literal: true

# CompanyCreditDeduction::BaseService — the epic credit-deduction service.
#
# CONTROLLER-ONLY. This service must never be called from a background job,
# import, seed, or data migration. Background jobs are free-credit: they may
# grant credits (top-ups, promo campaigns) and drain usage counters, but they
# must not take credits out of a wallet. The only caller is
# Companies::CreditDeductionConcern's after_action DSL; controllers declare the
# service per action and never deduct inline.
#
# One purpose: move credits out of the company wallet for a single controller
# action and meter the usage. Subclasses represent ONE place/controller action
# (e.g. CompanyCreditDeduction::Companies::Dashboards::IndexService) because the
# deduction rules can differ between places even for the same action type
# (cost, description, guards).
#
# Deduction priority: promo balance first (while positive), then main absorbs
# the remainder. Main may go negative when the balance is insufficient. The
# service never raises for a low balance. If the balance was already negative
# before the deduction, it logs a warning and rechecks workflow_status.
module CompanyCreditDeduction
  class BaseService
    def self.call(company:, **kwargs)
      new(company: company, **kwargs).call
    end

    def initialize(company:, **kwargs)
      @company = company
    end

    def call
      return unless should_run?
      return if cost.zero?

      wallet = @company.company_wallet
      return unless wallet

      deduct(wallet, cost)
      @company.record_credit_usage!(cost)
      true
    end

    private

    # -- Subclass contract -----------------------------------------------------

    # String key mirrored in CREDIT_USAGE_RATES and CompanyUsageLog.action_type.
    def action_type
      raise NotImplementedError, "#{self.class} must implement #action_type"
    end

    # Human-readable description stored on wallet audit logs.
    def description
      action_type.to_s.tr("_", " ")
    end

    # Credit cost — resolved from CREDIT_USAGE_RATES by default; subclasses
    # can override for place-specific pricing.
    def cost
      CREDIT_USAGE_RATES.fetch(action_type.to_sym, 0)
    end

    # Subclasses can guard the deduction (e.g. only for JSON requests,
    # only when a feature is enabled).
    def should_run?
      @company.present?
    end

    # -- Deduction core --------------------------------------------------------

    def deduct(wallet, amount)
      balance_before = wallet.total_credit_balance
      was_negative = balance_before.negative?

      remaining = deduct_from_balance(wallet, :promo, amount)
      if remaining.positive?
        wallet.deduct_from!(
          balance: :main, amount: remaining,
          source: @company, description: description, action_type: action_type
        )
      end

      return unless was_negative

      balance_after = wallet.total_credit_balance
      Rails.logger.warn(
        "[CompanyCreditDeduction] deduction while negative " \
        "company=#{@company.id} action=#{action_type} " \
        "balance_before=#{balance_before} cost=#{amount} balance_after=#{balance_after}"
      )
      @company.sync_credit_status!(total_credit_balance: balance_after)
    end

    # Drains as much as possible from one balance; returns the remaining amount.
    # A non-positive balance (already empty or negative) is left untouched.
    def deduct_from_balance(wallet, balance, amount)
      return amount if amount.zero?

      available = wallet.public_send(CompanyWallet::BALANCES.fetch(balance))
      return amount if available <= 0

      taken = [ amount, available ].min
      wallet.deduct_from!(
        balance: balance, amount: taken,
        source: @company, description: description, action_type: action_type
      )
      amount - taken
    end
  end
end
