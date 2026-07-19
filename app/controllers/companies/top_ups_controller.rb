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
    bpm = BillingPaymentMethod.find(params[:billing_payment_method_id])

    result = TopUps::CreateService.new(
      company: current_company,
      amount_cents: params[:amount_cents],
      billing_payment_method: bpm
    ).call

    render json: { qr_string: result.qr_string }
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
