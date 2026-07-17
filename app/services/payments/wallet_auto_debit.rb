module Payments
  class WalletAutoDebit
    def initialize(amount_cents:, invoice_id:, transaction_token:, memo:, gateway_url:, secret_key:, **_args)
      @amount_cents = amount_cents
      @invoice_id = invoice_id
      @transaction_token = transaction_token
      @memo = memo
      @gateway_url = gateway_url
      @secret_key = secret_key
    end

    def call
      {
        success: true,
        gateway_reference: "WALLET_#{Time.current.to_i}",
        gateway_payload: { memo: @memo }
      }
    end
  end
end
