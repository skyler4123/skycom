module Payments
  class WalletAutoDebit
    def initialize(amount_cents:, invoice_id:, memo:, **_args)
      @amount_cents = amount_cents
      @invoice_id = invoice_id
      @memo = memo
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
