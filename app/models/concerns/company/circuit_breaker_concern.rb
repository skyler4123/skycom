# frozen_string_literal: true

module Company::CircuitBreakerConcern
  extend ActiveSupport::Concern

  included do
    after_update :auto_reset_circuit_breaker, if: -> { saved_change_to_main_balance_cents? || saved_change_to_promo_balance_cents? }
  end

  def circuit_breaker_trip!
    return if lifecycle_status_suspended?

    update!(lifecycle_status: :suspended)
  end

  def circuit_breaker_reset!
    return unless lifecycle_status_suspended?

    update!(lifecycle_status: :active)
  end

  private

  def auto_reset_circuit_breaker
    return unless lifecycle_status_suspended?
    return if debt_ceiling_reached?

    circuit_breaker_reset!
  end
end
