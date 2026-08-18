# frozen_string_literal: true

# Top-up page — displays the country-based top-up options (from CREDIT_RATES)
# and the company's payment options (b2b BillingPaymentMethod catalog).
# Submission/payment flow is still future work.
class Companies::TopUpsController < Companies::ApplicationController
  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        rates = CREDIT_RATES[current_company.country.to_sym] || {}
        render json: {
          top_up_options: rates.map { |money_cents, credits|
            { money_amount_cents: money_cents, credit_amount: credits }
          },
          payment_methods: BillingPaymentMethod.where(business_type: :b2b).order(:lifecycle_status).map { |m|
            m.as_json(only: %i[id name code payment_mode strategy lifecycle_status])
          }
        }
      end
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
