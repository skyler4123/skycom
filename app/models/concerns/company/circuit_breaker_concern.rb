# frozen_string_literal: true

# Manages Company lifecycle based on unpaid invoices.
#
# flag_unpaid! is called when unpaid invoices exist:
#   - Sets has_unpaid_invoices_at = Time.current
#   - Sets suspension_at = end of current month (gives runway before suspension)
#
# Admin can extend suspension_at to give more time.
# A cronjob (SyncSuspensionJob) runs daily at midnight to suspend companies
# whose suspension_at has passed → sets lifecycle_status to :suspended.
#
# mark_suspended! is called by the cronjob when suspension_at has passed:
#   - Sets lifecycle_status to :suspended
#
# is_accessible? checks lifecycle_status_suspended? (status IS the source of truth).
# check_accessable in Authorizable concern gates access using is_accessible?.
#
# try_reactivate! is called after an invoice is marked paid:
#   - Clears has_unpaid_invoices_at, clears suspension_at
#   - Sets lifecycle_status to :active (unsuspends the company)
#
# auto_settle_unpaid_invoices fires:
#   - On balance change (main or promo)
#   - After an unpaid BillingInvoice is created (via BillingInvoice callback)
#   Tries to settle unpaid invoices oldest-first from wallet.
#
# disabled is terminal — no transitions out of it.
#
module Company::CircuitBreakerConcern
  extend ActiveSupport::Concern

  TERMINAL_STATES = %w[disabled].freeze

  included do
    after_update :auto_settle_unpaid_invoices, if: -> { saved_change_to_main_balance_cents? || saved_change_to_promo_balance_cents? }
  end

  def flag_unpaid!
    assert_not_terminal!
    return if has_unpaid_invoices_at.present?

    update!(
      has_unpaid_invoices_at: Time.current,
      suspension_at: Time.current.end_of_month
    )
  end

  def mark_suspended!
    assert_not_terminal!
    return if lifecycle_status_suspended?

    update!(lifecycle_status: :suspended)
  end

  def try_reactivate!
    return if lifecycle_status_disabled?
    return if billing_invoices.where(payment_status: %i[unpaid overdue]).exists?

    update!(lifecycle_status: :active, suspension_at: nil, has_unpaid_invoices_at: nil)
  end

  def is_accessible?
    !lifecycle_status_suspended?
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
