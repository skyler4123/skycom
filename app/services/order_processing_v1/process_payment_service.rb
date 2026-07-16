module OrderProcessingV1
  class ProcessPaymentService
    def self.call(order:)
      invoice = Invoice.create!(
        company_id: order.company_id,
        branch_id: order.branch_id,
        order_id: order.id,
        name: "Invoice for Order #{order.id}",
        code: "INV-#{Time.current.to_i}-#{SecureRandom.hex(3).upcase}",
        total_price: order.order_appointments.sum(:total_price) || 0,
        currency_code: order.currency_code,
        workflow_status: :paid,
        business_type: :sales
      )

      transaction = Transaction.create!(
        company_id: order.company_id,
        branch_id: order.branch_id,
        invoice_id: invoice.id,
        amount_cents: invoice.total_price_cents,
        currency_code: order.currency_code,
        workflow_status: :completed,
        business_type: :standard_payment
      )

      order.update!(workflow_status: :paid)

      { transaction_id: transaction.id }
    end
  end
end
