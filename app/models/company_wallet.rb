# frozen_string_literal: true

# CompanyWallet — Atomic purpose: store the credit balance NUMBER only.
# No business logic. Balance changes flow exclusively through the chain
# (CompanyTransaction → CompanyInvoice → CompanyOrder → CompanyWallet);
# the wallet exposes only low-level add_credits!/deduct_credits! entry points.
# Atomicity: deduct uses a conditional UPDATE (balance >= amount) so no
# concurrent deduction can overdraw; lock_version provides optimistic locking.
class CompanyWallet < ApplicationRecord
  USAGE_LOGGING_WINDOW = 5.minutes

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :walletable, polymorphic: true
  has_many :company_wallet_logs, dependent: :destroy
  has_many :company_usage_logs, dependent: :destroy

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true, default: :active
  enum :workflow_status, WORKFLOW_STATUS, prefix: true, default: :confirmed

  class InsufficientCreditsError < StandardError; end

  # The only mutation entry points — called exclusively by the chain
  # (CompanyOrder#complete!) and by usage-deduction services.

  def add_credits!(amount:, source: nil, description: nil, action_type: "top_up")
    raise ArgumentError, "amount must be a positive integer" unless amount.is_a?(Integer) && amount.positive?

    before = credit_balance
    ActiveRecord::Base.transaction do
      self.class.where(id: id)
        .update_all([ "credit_balance = credit_balance + ?, lock_version = lock_version + 1", amount ])
      reload
      CompanyWalletLog.create!(
        company: company, company_wallet: self, change_type: :credit,
        change_amount: amount, balance_before: before, balance_after: credit_balance,
        source: source, description: description
      )
      record_usage_log!(action_type: action_type, source: source, change_amount: amount, description: description)
    end
    credit_balance
  end

  def deduct_credits!(amount:, source: nil, description: nil, action_type: "deduction")
    raise ArgumentError, "amount must be a positive integer" unless amount.is_a?(Integer) && amount.positive?

    before = credit_balance
    ActiveRecord::Base.transaction do
      updated = self.class.where(id: id)
        .where("credit_balance >= ?", amount)
        .update_all([ "credit_balance = credit_balance - ?, lock_version = lock_version + 1", amount ])
      raise InsufficientCreditsError, "Insufficient credits (balance: #{before}, required: #{amount})" unless updated == 1

      reload
      CompanyWalletLog.create!(
        company: company, company_wallet: self, change_type: :debit,
        change_amount: -amount, balance_before: before, balance_after: credit_balance,
        source: source, description: description
      )
      record_usage_log!(action_type: action_type, source: source, change_amount: -amount, description: description)
    end
    credit_balance
  end

  def usage_logging_active?
    usage_logging_until.present? && usage_logging_until > Time.current
  end

  def enable_usage_logging!(window: USAGE_LOGGING_WINDOW)
    update!(usage_logging_until: Time.current + window)
  end

  def disable_usage_logging!
    update!(usage_logging_until: nil)
  end

  private

  def record_usage_log!(action_type:, source:, change_amount:, description:)
    return unless usage_logging_active?

    CompanyUsageLog.create!(
      company: company, company_wallet: self,
      action_type: action_type, change_amount: change_amount,
      balance_after: credit_balance, source: source, description: description
    )
  end
end
