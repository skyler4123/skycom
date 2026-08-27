# frozen_string_literal: true

# Cancels an abandoned POS payment: releases the stock reservation and marks
# the pending Transaction failed. Only pending transactions can cancel.
module OrderProcessingV1
  class CancelPaymentService
    def self.call(transaction_token:, company:)
      # TODO: transaction_token (API param) vs gateway_reference (DB column) are the same value with different names — unify later.
      transaction = Transaction.find_by!(gateway_reference: transaction_token, company_id: company.id)
      return false unless transaction.pending?

      ReleaseReservedStockService.call(order: transaction.invoice.order)
      transaction.update!(status: :failed)
      true
    end
  end
end
