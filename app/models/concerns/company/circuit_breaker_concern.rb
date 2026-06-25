# frozen_string_literal: true

# Manages Company lifecycle transitions based on billing and enforcement state.
#
# mark_past_due! is called by SettlementService when payment collection fails:
#   company.mark_past_due!  # lifecycle_status → :past_due
#
# suspend! is the enforcement trip (admin or separate process):
#   company.suspend!         # lifecycle_status → :suspended
#
# The auto-reset callback fires on any balance change:
#   company.update!(main_balance_cents: 5000)
#   → if past_due/suspended + balance above threshold → lifecycle_status back to :active
#
# disabled is terminal — no transitions out of it.
#
module Company::CircuitBreakerConcern
  extend ActiveSupport::Concern

  TERMINAL_STATES = %w[disabled].freeze

  included do
    after_update :auto_reset_circuit_breaker, if: -> { saved_change_to_main_balance_cents? || saved_change_to_promo_balance_cents? }
  end

  def mark_past_due!
    assert_not_terminal!
    update!(lifecycle_status: :past_due) unless lifecycle_status_past_due?
  end

  def suspend!
    assert_not_terminal!
    update!(lifecycle_status: :suspended) unless lifecycle_status_suspended?
  end

  def circuit_breaker_reset!
    return unless lifecycle_status_past_due? || lifecycle_status_suspended?

    update!(lifecycle_status: :active)
  end

  private

  def assert_not_terminal!
    return unless lifecycle_status.to_s.in?(TERMINAL_STATES)

    errors.add(:base, "Cannot transition from terminal state: #{lifecycle_status}")
    raise ActiveRecord::RecordInvalid.new(self)
  end

  def auto_reset_circuit_breaker
    return unless lifecycle_status_past_due? || lifecycle_status_suspended?
    return if debt_ceiling_reached?

    circuit_breaker_reset!
  end
end
