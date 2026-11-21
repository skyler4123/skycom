# frozen_string_literal: true

# StoreManager::OrderFulfillmentService — the two floor actions on an order.
#
# Mark ready moves the fulfilment state to ready. Hand over requires a paid
# invoice and records handed_over_at; it never touches workflow_status, so
# payment/accounting and employee KPIs keep their meaning.
#
# Docs: docs/business_analysis/06-store-manager.md
class StoreManager::OrderFulfillmentService
  def self.mark_ready(company:, order:, now: Time.current)
    new(company: company, order: order, now: now).mark_ready
  end

  def self.hand_over(company:, order:, now: Time.current)
    new(company: company, order: order, now: now).hand_over
  end

  def initialize(company:, order:, now:)
    @company = company
    @order = order
    @now = now
  end

  def mark_ready
    order.with_lock do
      order.reload
      ensure_fulfillment_order!
      ensure_not_closed!

      if order.fulfillment_status_ready?
        return result("Order #{order.code} is already ready.")
      end

      order.update!(fulfillment_status: :ready)
      result("Order #{order.code} is ready for handover.")
    end
  end

  def hand_over
    order.with_lock do
      order.reload
      ensure_fulfillment_order!
      ensure_not_closed!

      if order.fulfillment_status_handed_over?
        return result("Order #{order.code} has already been handed over.")
      end

      unless paid?
        raise StoreManager::Error, "Order must be paid at POS before handover."
      end

      order.update!(fulfillment_status: :handed_over, handed_over_at: now)
      result("Order #{order.code} handed over.")
    end
  end

  private

  attr_reader :company, :order, :now

  def ensure_fulfillment_order!
    return unless order.fulfillment_channel_walk_in?

    raise StoreManager::Error, "Counter sales are handed over at checkout."
  end

  def ensure_not_closed!
    return unless order.workflow_status_cancelled? || order.workflow_status_refunded?

    raise StoreManager::Error, "Cancelled or refunded orders cannot be fulfilled."
  end

  def paid?
    return true if order.workflow_status_paid? || order.workflow_status_completed?

    order.invoices.where(payment_status: :paid).exists?
  end

  def result(message)
    { message: message, order: order }
  end
end
