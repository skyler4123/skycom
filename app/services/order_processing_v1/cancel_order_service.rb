# frozen_string_literal: true

# OrderProcessingV1::CancelOrderService — void a sale before it is paid.
#
# The order stays in the database as `cancelled` for audit. Pending transactions
# are failed (which releases their stock holds and discount), unpaid invoices
# are voided, and the order is marked cancelled. Paid sales belong to Orders /
# Refunds; this service refuses them.
module OrderProcessingV1
  class CancelOrderService
    def self.call(order:, company:)
      new(order: order, company: company).call
    end

    def initialize(order:, company:)
      @order = order
      @company = company
    end

    def call
      @order.with_lock do
        return success if @order.workflow_status_cancelled?
        return failure("Paid orders cannot be voided here") if @order.workflow_status_paid?
        return failure("Paid orders cannot be voided here") if paid_invoice_or_transaction?

        pending_transactions.each do |txn|
          CancelPaymentService.call(transaction_token: txn.gateway_reference, company: @company)
        end

        Discounts::ReleaseService.call(order: @order)
        @order.invoices.unpaid.each { |invoice| invoice.update!(payment_status: :voided) }
        @order.update!(workflow_status: :cancelled)
        success
      end
    end

    private

    def pending_transactions
      Transaction.joins(:invoice)
        .where(invoices: { order_id: @order.id }, status: :pending)
        .to_a
    end

    def paid_invoice_or_transaction?
      @order.invoices.where(payment_status: :paid).exists? ||
        Transaction.joins(:invoice)
          .where(invoices: { order_id: @order.id }, status: :completed)
          .exists?
    end

    def success
      { success: true, message: "Order voided" }
    end

    def failure(message)
      { success: false, errors: [ message ] }
    end
  end
end
