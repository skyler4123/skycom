# frozen_string_literal: true

# Manages Company lifecycle based on unpaid invoices.
#
# mark_past_due! is called when unpaid invoices exist:
#   - Sets lifecycle_status +:past_due
#   - Sets suspension_at + end of current month (gives runway)
#
# Admin can extend suspension_at to give more time.
# A company is NOT accessible when suspension_at.present? && suspension_at <= Time.current
# (checked via is_accessible?, gated by block_access! in Authorizable concern).
#
# try_reactivate! is called after an invoice is marked paid:
#   - If no unpaid invoices remain + sets lifecycle_status +:active, clears suspension_at
#
# auto_settle_unpaid_invoices fires:
#   - On balance change (main or promo)
#   - After an unpaid BillingInvoice is created (via BillingInvoice callback)
#   Tries to settle unpaid invoices oldest-first from wallet.
#
# disabled is terminal + no transitions out of it.
#
module Company::CircuitBreakerConcern
  extend ActiveSupport::Concern

  TERMINAL_STATES = %w[disabled].freeze

  included do
    after_update :auto_settle_unpaid_invoices, if: -> { saved_change_to_main_balance_cents? || saved_change_to_promo_balance_cents? }
  end

  def mark_past_due!
    assert_not_terminal!
    return if lifecycle_status_past_due?

    update!(
      lifecycle_status: :past_due,
      suspension_at: Time.current.end_of_month
    )
  end

  def try_reactivate!
    return if lifecycle_status_disabled?
    return if billing_invoices.where(payment_status: %i[unpaid overdue]).exists?

    update!(lifecycle_status: :active, suspension_at: nil)
  end

  def is_accessible?
    suspension_at.nil? || suspension_at > Time.current
  end

  def auto_settle_unpaid_invoices
    return if Thread.current[:__settling_company_id] == id
    return if lifecycle_status_disabled?
    return unless main_balance_cents.positive? || promo_balance_cents.positive?
    return unless billing_invoices.where(payment_status: %i[unpaid overdue]).exists?

    Thread.current[:__settling_company_id] = id
    begin
      Billing::SettlementService.settle_all(self)
    ensure
      Thread.current[:__settling_company_id] = nil
    end
  end

  private

  def assert_not_terminal!
    return unless lifecycle_status.to_s.in?(TERMINAL_STATES)

    errors.add(:base, "Cannot transition from terminal state: #{lifecycle_status}")
    raise ActiveRecord::RecordInvalid.new(self)
  end
end
