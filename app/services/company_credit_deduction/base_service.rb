# frozen_string_literal: true

# CompanyCreditDeduction::BaseService — the epic credit-deduction service.
#
# One purpose: move credits out of the company wallet for a single
# action (and meter the usage). Subclasses represent ONE place/controller
# action (e.g. CompanyCreditDeduction::Companies::Dashboards::IndexService) because the
# deduction rules can differ between places even for the same action type
# (cost, description, guards). Controllers trigger deduction via the
# CreditDeductionConcern after_action DSL — never inline in actions.
#
# Deduction priority: promo balance first, then main balance; any
# uncovered remainder is absorbed by the debt balance (normally 0).
# The service never raises for an insufficient balance — debt absorbs.
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
      amount = deduct_from_balance(wallet, :promo, amount)
      amount = deduct_from_balance(wallet, :main, amount)
      absorb_into_debt(wallet, amount) if amount.positive?
    end

    # Drains as much as possible from one balance; returns the remaining amount.
    def deduct_from_balance(wallet, balance, amount)
      return amount if amount.zero?

      available = wallet.public_send("#{CompanyWallet::BALANCES.fetch(balance)}")
      return amount if available.zero?

      taken = [ amount, available ].min
      wallet.deduct_from!(
        balance: balance, amount: taken,
        source: @company, description: description, action_type: action_type
      )
      amount - taken
    end

    def absorb_into_debt(wallet, amount)
      wallet.add_to!(
        balance: :debt, amount: amount,
        source: @company, description: description, action_type: action_type
      )
    end
  end
end
