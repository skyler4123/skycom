# frozen_string_literal: true

# Completes a pending POS Transaction: the model callback derives
# Invoice.payment_status, workflow statuses flip to paid, and async
# finalization is enqueued. Idempotent — only a pending transaction completes.
module OrderProcessingV1
  class CompletePaymentService
    def self.call(transaction:)
      new(transaction: transaction).call
    end

    def initialize(transaction:)
      @transaction = transaction
    end

    def call
      return false unless @transaction.pending?

      @transaction.with_lock do
        return false unless @transaction.reload.pending?

        ActiveRecord::Base.transaction do
          @transaction.update!(status: :completed)
          @transaction.invoice.update!(workflow_status: :paid)
          @transaction.invoice.order.update!(workflow_status: :paid)
        end
      end

      OrderProcessingV1::FinalizeJob.perform_later(@transaction.invoice.order_id)
      true
    end
  end
end
