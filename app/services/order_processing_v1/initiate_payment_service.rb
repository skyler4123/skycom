# frozen_string_literal: true

# Starts a POS payment: optionally reserves a single-use discount code,
# reserves stock, creates the Invoice (gross - discount) + pending Transaction
# audit row, then either completes synchronously (cash) or hands off to the
# configured gateway strategy (QR) using the branch appointment's merchant
# identity. Any failure after the discount reservation releases both the stock
# reservation and the discount code.
# TODO: transaction_token (Result/API) vs gateway_reference (Transaction DB column) name mismatch — unify later.
module OrderProcessingV1
  class InitiatePaymentService
    Result = Struct.new(:status, :order_id, :transaction_id, :transaction_token,
      :qr_string, :discount, keyword_init: true)

    def self.call(order:, appointment:, discount_code: nil, employee: nil)
      new(order: order, appointment: appointment,
        discount_code: discount_code, employee: employee).call
    end

    def initialize(order:, appointment:, discount_code: nil, employee: nil)
      @order = order
      @appointment = appointment
      @discount_code = discount_code
      @employee = employee
    end

    def call
      validate_appointment!
      discount = apply_discount!

      begin
        reserved = OrderProcessingV1::ReserveStockService.call(items: build_items)[:reserved]

        ActiveRecord::Base.transaction do
          invoice = create_invoice
          txn = create_transaction(invoice)

          if qr_mode?
            initiate_gateway(txn, invoice)
            Result.new(status: "pending", order_id: @order.id,
              transaction_token: txn.gateway_reference,
              qr_string: txn.gateway_payload["qr_string"],
              discount: discount)
          else
            OrderProcessingV1::CompletePaymentService.call(transaction: txn)
            Result.new(status: "paid", order_id: @order.id, transaction_id: txn.id,
              discount: discount)
          end
        end
      rescue StandardError
        reserved&.each { |r| r[:stock].release_reserved!(r[:qty]) }
        discount&.release!
        raise
      end
    end

    private

    def validate_appointment!
      valid = @appointment.is_a?(BranchPaymentMethodAppointment) &&
        @appointment.branch_id == @order.branch_id &&
        @appointment.lifecycle_status == "active"
      raise InvalidPaymentMethodError, "Payment method is not available for this branch" unless valid
    end

    # Reserve the single-use code before any side effects. On success the code
    # is pending and bound to the order; failures raise (nothing to unwind).
    def apply_discount!
      return nil if @discount_code.blank?

      result = Discounts::ApplyService.call(
        company: @order.company, order: @order,
        code: @discount_code, employee: @employee
      )
      raise InvalidDiscountError, result[:errors].to_sentence unless result[:success]

      @discount = result[:discount]
    end

    def build_items
      @order.order_product_appointments.map do |oa|
        stock = @order.company.stocks.find_by!(product_id: oa.product_id)
        { stock_id: stock.id, quantity: oa.quantity }
      end
    end

    def create_invoice
      gross = (@order.line_total * 100).to_i
      Invoice.create!(
        company_id: @order.company_id,
        branch_id: @order.branch_id,
        order_id: @order.id,
        name: "Invoice for Order #{@order.id}",
        code: "INV-#{Time.current.to_i}-#{SecureRandom.hex(3).upcase}",
        price_cents: [ gross - (@discount&.amount_cents || 0), 0 ].max,
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
        gateway_reference: "POS_#{SecureRandom.hex(16)}" # TODO: column gateway_reference exposed as transaction_token — unify naming
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
