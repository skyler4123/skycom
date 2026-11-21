# frozen_string_literal: true

# CompanyCreditDeduction::BaseService — the deduction core.
#
# One purpose: move credits out of the company wallet for one charge and meter
# the usage. The public API is
# CompanyCreditDeduction::DeductionService.call(...); this base keeps the
# priority rules, audit logs, metering, and status sync so every caller shares
# one write path. It is safe to call from controllers, models, jobs, and
# mailers — suspended companies are guarded in DeductionService.
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
      return false unless should_run?
      return false unless cost.is_a?(Integer) && cost.positive?

      wallet = @company.company_wallet
      return false unless wallet

      deduct(wallet, cost)
      @company.record_credit_usage!(cost)
      true
    end

    private

    # -- Subclass contract -----------------------------------------------------

    # String key mirrored in CREDIT_DEDUCTION_ACTION_TYPES and
    # CompanyUsageLog.action_type.
    def action_type
      raise NotImplementedError, "#{self.class} must implement #action_type"
    end

    # Human-readable description stored on wallet audit logs.
    def description
      action_type.to_s.tr("_", " ")
    end

    # Credit cost. The generic service supplies an explicit amount; specialized
    # subclasses may override this.
    def cost
      0
    end

    # Domain record that caused the charge (optional). Defaults to the company.
    def source
      @company
    end

    # Optional retry key written to wallet/usage logs and checked by
    # DeductionService before charging.
    def external_id
      nil
    end

    # Subclasses can guard the deduction (e.g. only when a feature is enabled).
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
          source: source, description: description, action_type: action_type,
          external_id: external_id
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
      available = wallet.public_send(CompanyWallet::BALANCES.fetch(balance))
      return amount if available <= 0

      taken = [ amount, available ].min
      wallet.deduct_from!(
        balance: balance, amount: taken,
        source: source, description: description, action_type: action_type,
        external_id: external_id
      )
      amount - taken
    end
  end
end
