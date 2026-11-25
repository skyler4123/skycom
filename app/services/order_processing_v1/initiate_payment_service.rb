# frozen_string_literal: true

# Starts a POS payment: optionally reserves a single-use discount code,
# reserves stock, creates the Invoice (total including tax) + pending
# Transaction audit row, then either completes synchronously (cash) or hands
# off to the configured gateway strategy (QR) using the branch appointment's
# merchant identity. Any failure after the discount reservation releases both
# the stock reservation and the discount code.
# TODO: transaction_token (Result/API) vs gateway_reference (Transaction DB column) name mismatch — unify later.
module OrderProcessingV1
  class InitiatePaymentService
    Result = Struct.new(
      :status, :order_id, :transaction_id, :transaction_token, :qr_string,
      :discount, :subtotal_cents, :discount_cents, :tax_cents, :added_tax_cents,
      :total_cents, :currency, :tax_lines, :cash_received_cents, :change_cents,
      keyword_init: true
    )

    def self.call(order:, appointment:, discount_code: nil, employee: nil, cash_received_cents: nil)
      new(order: order, appointment: appointment,
        discount_code: discount_code, employee: employee,
        cash_received_cents: cash_received_cents).call
    end

    def initialize(order:, appointment:, discount_code: nil, employee: nil, cash_received_cents: nil)
      @order = order
      @appointment = appointment
      @discount_code = discount_code
      @employee = employee
      @cash_received_cents = cash_received_cents.presence&.to_i
    end

    def call
      validate_order_state!
      validate_appointment!
      @discount = resolve_discount!
      @totals = OrderTotalsService.call(order: @order, discount_cents: @discount&.amount_cents.to_i)
      validate_cash! if cash_mode?

      begin
        reserved = OrderProcessingV1::ReserveStockService.call(items: build_items)[:reserved]

        ActiveRecord::Base.transaction do
          PersistLineTaxesService.call(line_taxes: @totals.line_taxes)
          @order.update_columns(tax_cents: @totals.tax_cents, total_cents: @totals.total_cents)
          invoice = create_invoice
          txn = create_transaction(invoice)

          if qr_mode?
            initiate_gateway(txn, invoice)
            Result.new(
              status: "pending", order_id: @order.id,
              transaction_token: txn.gateway_reference,
              qr_string: txn.gateway_payload["qr_string"],
              discount: @discount, **totals_payload
            )
          else
            OrderProcessingV1::CompletePaymentService.call(transaction: txn)
            Result.new(
              status: "paid", order_id: @order.id, transaction_id: txn.id,
              discount: @discount, **totals_payload
            )
          end
        end
      rescue StandardError
        reserved&.each do |r|
          StockPendings::ReleaseService.call(stock_pending: r[:stock_pending]) if r[:stock_pending]
        end
        @discount&.release!
        raise
      end
    end

    private

    def totals_payload
      {
        subtotal_cents: @totals.subtotal_cents,
        discount_cents: @totals.discount_cents,
        tax_cents: @totals.tax_cents,
        added_tax_cents: @totals.added_tax_cents,
        total_cents: @totals.total_cents,
        currency: @totals.currency,
        tax_lines: @totals.tax_lines,
        cash_received_cents: cash_mode? ? @cash_received_cents : nil,
        change_cents: cash_mode? ? change_cents : nil
      }
    end

    def validate_order_state!
      return if @order.workflow_status_pending?

      raise InvalidOrderStateError, "Order is not payable"
    end

    def validate_appointment!
      valid = @appointment.is_a?(BranchPaymentMethodAppointment) &&
        @appointment.branch_id == @order.branch_id &&
        @appointment.lifecycle_status == "active"
      raise InvalidPaymentMethodError, "Payment method is not available for this branch" unless valid
    end

    # Reserve the single-use code against the order. The POS applies the code
    # after ORDER, so pay normally finds an existing pending discount. A code
    # passed to pay is kept for backwards compatibility and replaces the old
    # reservation only after the new one succeeds.
    def resolve_discount!
      existing = @order.discounts.status_pending.first
      return existing if @discount_code.blank?

      normalized = @discount_code.to_s.strip.upcase
      return existing if existing && existing.code == normalized

      result = Discounts::ApplyService.call(
        company: @order.company, order: @order,
        code: @discount_code, employee: @employee
      )
      raise InvalidDiscountError, result[:errors].to_sentence unless result[:success]

      existing&.release! if existing
      result[:discount]
    end

    def validate_cash!
      return if @cash_received_cents.nil?
      return if @cash_received_cents >= @totals.total_cents

      raise InvalidPaymentAmountError, "Cash received is less than the total"
    end

    def change_cents
      return 0 if @cash_received_cents.nil?

      [ @cash_received_cents - @totals.total_cents, 0 ].max
    end

    def build_items
      @order.order_product_appointments.map do |oa|
        stock = resolve_stock(oa)
        oa.update!(stock_id: stock.id) # persist the reserved stock for finalize
        { stock_id: stock.id, quantity: oa.quantity }
      end
    end

    # Stock belongs to a warehouse (docs/superpowers/specs/2026-09-23-stock-source-of-truth-
    # design.md): use the exact row chosen at checkout, else resolve against
    # the order's branch warehouses — never a company-wide first match.
    def resolve_stock(oa)
      if oa.stock_id.present?
        stock = @order.company.stocks
          .joins(:warehouse)
          .find_by(id: oa.stock_id, warehouses: { branch_id: @order.branch_id })
        return stock if stock
      end

      @order.company.stocks
        .joins(:warehouse)
        .find_by!(product_id: oa.product_id, warehouses: { branch_id: @order.branch_id })
    rescue ActiveRecord::RecordNotFound
      raise OrderProcessingV1::InsufficientStockError,
        "Product is not stocked in this branch"
    end

    def create_invoice
      Invoice.create!(
        company_id: @order.company_id,
        branch_id: @order.branch_id,
        order_id: @order.id,
        name: "Invoice for Order #{@order.id}",
        code: "INV-#{Time.current.to_i}-#{SecureRandom.hex(3).upcase}",
        price_cents: @totals.total_cents,
        tax_cents: @totals.tax_cents,
        total_cents: @totals.total_cents,
        currency: @order.currency,
        business_type: :sales,
        tax_breakdown: @totals.tax_lines.map { |line| line.transform_keys(&:to_s) }
      )
    end

    def create_transaction(invoice)
      txn = Transaction.create!(
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

      if cash_mode? && @cash_received_cents
        txn.update!(cash_received_cents: @cash_received_cents, change_cents: change_cents)
      end

      txn
    end

    def payment_mode
      @appointment.payment_method.payment_mode
    end

    def cash_mode?
      payment_mode.to_s == "cash"
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
