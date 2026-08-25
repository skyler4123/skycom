# frozen_string_literal: true

# Starts a POS payment: reserves stock, creates the Invoice + pending
# Transaction audit row, then either completes synchronously (cash) or hands
# off to the configured gateway strategy (QR) using the branch appointment's
# merchant identity. Any post-reservation failure releases the reservation.
module OrderProcessingV1
  class InitiatePaymentService
    Result = Struct.new(:status, :order_id, :transaction_id, :transaction_token, :qr_string, keyword_init: true)

    def self.call(order:, appointment:)
      new(order: order, appointment: appointment).call
    end

    def initialize(order:, appointment:)
      @order = order
      @appointment = appointment
    end

    def call
      validate_appointment!

      reserved = OrderProcessingV1::ReserveStockService.call(items: build_items)[:reserved]

      begin
        ActiveRecord::Base.transaction do
          invoice = create_invoice
          txn = create_transaction(invoice)

          if qr_mode?
            initiate_gateway(txn, invoice)
            Result.new(status: "pending", order_id: @order.id,
              transaction_token: txn.gateway_reference,
              qr_string: txn.gateway_payload["qr_string"])
          else
            OrderProcessingV1::CompletePaymentService.call(transaction: txn)
            Result.new(status: "paid", order_id: @order.id, transaction_id: txn.id)
          end
        end
      rescue StandardError
        reserved.each { |r| r[:stock].release_reserved!(r[:qty]) }
        raise
      end
    end

    private

    def validate_appointment!
      valid = @appointment.appoint_to_type == "Branch" &&
        @appointment.appoint_to_id == @order.branch_id &&
        @appointment.lifecycle_status == "active"
      raise InvalidPaymentMethodError, "Payment method is not available for this branch" unless valid
    end

    def build_items
      @order.order_appointments.map do |oa|
        stock = @order.company.stocks.find_by!(product_id: oa.appoint_to.id)
        { stock_id: stock.id, quantity: oa.quantity }
      end
    end

    def create_invoice
      Invoice.create!(
        company_id: @order.company_id,
        branch_id: @order.branch_id,
        order_id: @order.id,
        name: "Invoice for Order #{@order.id}",
        code: "INV-#{Time.current.to_i}-#{SecureRandom.hex(3).upcase}",
        price_cents: (@order.order_appointments.sum(:total_price) * 100).to_i,
        currency: @order.currency,
        business_type: :sales
      )
    end

    def create_transaction(invoice)
      Transaction.create!(
        company_id: @order.company_id,
        branch_id: @order.branch_id,
        invoice_id: invoice.id,
        price_cents: invoice.price_cents,
        currency: @order.currency,
        status: :pending,
        business_type: :standard_payment,
        payment_method_id: @appointment.payment_method_id,
        gateway_reference: "POS_#{SecureRandom.hex(16)}"
      )
    end

    def qr_mode?
      @appointment.payment_method.qr?
    end

    def initiate_gateway(txn, invoice)
      strategy_key = @appointment.payment_method.strategy.to_sym
      gateway_class_name = GATEWAY_STRATEGY_CLASSES[strategy_key]
      raise InvalidPaymentMethodError, "Unsupported POS payment strategy: #{strategy_key}" unless gateway_class_name

      result = gateway_class_name.constantize.new(
        amount_cents: invoice.price_cents,
        invoice_id: invoice.id,
        memo: invoice.code,
        transaction_token: txn.gateway_reference,
        merchant_number: @appointment.merchant_number,
        merchant_name: @appointment.merchant_name,
        merchant_id: @appointment.merchant_id
      ).call

      raise InvalidPaymentMethodError, result[:error] || "Gateway execution failed" unless result[:success]

      txn.update!(gateway_payload: result[:gateway_payload] || {})
    end
  end
end
