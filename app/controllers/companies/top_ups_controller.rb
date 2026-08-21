# frozen_string_literal: true

# Top-up page — displays the country-based top-up options (from CREDIT_RATES)
# and the company's payment options (b2b CompanyPaymentMethod catalog), and
# initiates the selected gateway flow (Mock QR / Mock Redirect).
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
          payment_methods: CompanyPaymentMethod.where(business_type: :b2b).order(:lifecycle_status).map { |m|
            m.as_json(only: %i[id name code payment_mode strategy lifecycle_status])
          }
        }
      end
    end
  end

  def mock_qr_gateway
    bpm = CompanyPaymentMethod.find_by!(strategy: :mock_qr_gateway)
    result = TopUps::CreateService.new(
      company: current_company,
      money_amount_cents: params[:money_amount_cents],
      company_payment_method: bpm
    ).call
    render json: { qr_string: result.qr_string }
  rescue TopUps::Error => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  def mock_redirect_gateway
    bpm = CompanyPaymentMethod.find_by!(strategy: :mock_redirect_gateway)
    result = TopUps::CreateService.new(
      company: current_company,
      money_amount_cents: params[:money_amount_cents],
      company_payment_method: bpm,
      redirect_url: company_usage_url(current_company)
    ).call
    render json: { redirect_url: result.redirect_url }
  rescue TopUps::Error => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end
end
