# frozen_string_literal: true

class Companies::TopUpsController < Companies::ApplicationController
  skip_before_action :check_accessable

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: billing_payment_methods_json }
    end
  end

  def create
    # bpm = BillingPaymentMethod.find(params[:billing_payment_method_id])

    # result = TopUps::CreateService.new(
    #   company: current_company,
    #   amount_cents: params[:amount_cents],
    #   billing_payment_method: bpm
    # ).call

    # render json: {
    #   qr_string: result.qr_string,
    #   websocket_url: result.websocket_url,
    #   websocket_token: result.websocket_token,
    #   websocket_channel: result.websocket_channel
    # }

    render json: {
      "qr_string": "00020101021238580010A0000|AMT:1000000|INV:9f33e4d5-5627-4a30-b5c4-cc156cacd9e7|TOKEN:TOPUP_94fe52f5f583d2130be7618b713e7d80|TXN:TXN_QR_1784363606344135871",
      "websocket_url": "ws://localhost:8000/connection/websocket",
      "websocket_token": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJkZjBmOTk1MC00ZDgyLTRkY2EtYmEzMi1hMGQxZTFhOGRmMTAiLCJjaGFubmVscyI6WyJjb21wYW55XzAxOWY3MWZmLTk0NWMtNzk3ZS05OTU2LTZjZTRkOWQzYThhNl90b3BfdXAiXX0.i3FklRwe099ESyGBAKuceX52hfak6JofHjyvazYirY8",
      "websocket_channel": "company_019f71ff-945c-797e-9956-6ce4d9d3a8a6_top_up"
    }
  rescue TopUps::Error => e
    render json: { errors: [ e.message ] }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def billing_payment_methods_json
    methods = BillingPaymentMethod.where(business_type: :b2b)
                                  .where(strategy: GATEWAY_STRATEGIES.values_at(:mock_qr_gateway, :mock_redirect_gateway))
                                  .map do |bpm|
      {
        id: bpm.id,
        name: bpm.name,
        description: bpm.description,
        code: bpm.code,
        strategy: bpm.strategy,
        payment_mode: bpm.payment_mode
      }
    end

    { billing_payment_methods: methods }
  end
end
