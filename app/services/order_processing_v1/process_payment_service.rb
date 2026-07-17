module OrderProcessingV1
  class ProcessPaymentService
    def self.call(order:)
      invoice = Invoice.create!(
        company_id: order.company_id,
        branch_id: order.branch_id,
        order_id: order.id,
        name: "Invoice for Order #{order.id}",
        code: "INV-#{Time.current.to_i}-#{SecureRandom.hex(3).upcase}",
        price_cents: (order.order_appointments.sum(:total_price) * 100).to_i || 0,
        currency: order.currency,
        workflow_status: :paid,
        business_type: :sales
      )

      transaction = Transaction.create!(
        company_id: order.company_id,
        branch_id: order.branch_id,
        invoice_id: invoice.id,
        price_cents: invoice.price_cents,
        currency: order.currency,
        workflow_status: :completed,
        business_type: :standard_payment
      )

      order.update!(workflow_status: :paid)

      { transaction_id: transaction.id }
    end
  end
end
