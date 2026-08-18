# frozen_string_literal: true

# Resolves a CompanyTransaction's billing_payment_method strategy to its
# gateway service class and executes the gateway call. On success the
# transaction keeps status :pending (the webhook later completes it); on
# failure it is marked :failed and an error is raised.
module Payments
  class InitiateService
    def initialize(transaction:, redirect_url: nil)
      @transaction = transaction
      @redirect_url = redirect_url
    end

    def call
      payment_method = @transaction.billing_payment_method
      strategy_key = payment_method.strategy&.to_sym

      gateway_class_name = GATEWAY_STRATEGY_CLASSES[strategy_key]
      raise TopUps::Error, "Unsupported payment strategy: #{strategy_key}" unless gateway_class_name

      gateway = gateway_class_name.constantize.new(
        amount_cents: @transaction.money_amount_cents,
        invoice_id: @transaction.company_invoice.id,
        memo: "SKYCOM #{@transaction.company_invoice.id}",
        transaction_token: @transaction.gateway_reference,
        redirect_url: @redirect_url
      )

      result = gateway.call

      if result[:success]
        @transaction.update!(
          status: :pending,
          gateway_payload: result[:gateway_payload]
        )
        @transaction
      else
        @transaction.update!(status: :failed, gateway_payload: result[:gateway_payload] || {})
        raise TopUps::Error, "Gateway execution failed: #{result[:error]}"
      end
    end
  end
end
