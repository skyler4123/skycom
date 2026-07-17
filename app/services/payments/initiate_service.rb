module Payments
  class InitiateService
    def initialize(transaction:)
      @transaction = transaction
    end

    def call
      payment_method = @transaction.try(:payment_method) || @transaction.try(:billing_payment_method)
      invoice = @transaction.try(:invoice) || @transaction.try(:billing_invoice)
      amount_cents = @transaction.try(:amount_cents) || @transaction.try(:price_cents)

      strategy_key = payment_method.strategy&.to_sym

      gateway_class_name = GATEWAY_STRATEGY_CLASSES[strategy_key]
      raise "Unsupported payment strategy: #{strategy_key}" unless gateway_class_name

      gateway_class = gateway_class_name.constantize

      gateway = gateway_class.new(
        amount_cents: amount_cents,
        invoice_id: invoice.id,
        memo: "SKYCOM #{invoice.id}",
        gateway_url: payment_method.gateway_url,
        secret_key: payment_method.secret_key,
        redirect_url: payment_method.respond_to?(:redirect_url) ? payment_method.redirect_url : nil
      )

      result = gateway.call

      if result[:success]
        @transaction.update!(
          gateway_reference: result[:gateway_reference],
          gateway_payload: result[:gateway_payload],
          status: :pending
        )
        @transaction
      else
        @transaction.update!(status: :failed)
        raise "Gateway execution failed: #{result[:error]}"
      end
    end
  end
end
