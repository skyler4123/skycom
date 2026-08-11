# frozen_string_literal: true

# PLACEHOLDER CONTROLLER — future Token implementation.
#
# The billing system was removed; company-level payments will use a Token
# system instead (e.g. deposit $10 → receive 1,000,000 tokens, an order
# consumes 10 tokens, dashboard access costs 2 tokens per visit).
#
# Actions are kept as placeholders — no logic yet. Wire the token flow here
# when the Token model/ledger is implemented.
class Companies::TopUpsController < Companies::ApplicationController
  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { billing_payment_methods: [] } }
    end
  end

  def mock_qr_gateway
    # TODO: Token implementation — generate a QR payment for a token top-up.
    render json: { status: "ok" }
  end

  def mock_redirect_gateway
    # TODO: Token implementation — create a hosted redirect session for a token top-up.
    render json: { status: "ok" }
  end
end
