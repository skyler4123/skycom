# frozen_string_literal: true

# Companies::TaxCodesController — company-scoped tax code catalog.
# Serves Stimulus: Companies_TaxCodes_IndexController +
#                  Companies_TaxCodes_NewModalController/EditModalController
# Endpoints: GET/POST /companies/:company_id/tax_codes(.json),
#            PATCH/DELETE /companies/:company_id/tax_codes/:id(.json)
# Docs: docs/superpowers/specs/2026-11-25-per-resource-tax-design.md
class Companies::TaxCodesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        codes = current_company.tax_codes.kept.ordered
        product_counts, service_counts = usage_counts(codes.map(&:id))

        render json: {
          tax_codes: codes.map { |code| format_tax_code(code, product_counts, service_counts) }
        }
      end
    end
  end

  def create
    attributes = tax_code_attributes
    return render_rate_error unless attributes

    code = current_company.tax_codes.new(attributes)

    if code.save
      render json: { tax_code: format_tax_code(code), message: "Tax code created" }, status: :created
    else
      render json: { errors: code.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    code = current_company.tax_codes.kept.find(params[:id])
    attributes = tax_code_attributes
    return render_rate_error unless attributes

    if code.update(attributes)
      render json: { tax_code: format_tax_code(code), message: "Tax code updated" }
    else
      render json: { errors: code.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    code = current_company.tax_codes.kept.find(params[:id])
    TaxCodes::DiscardService.call(tax_code: code)

    render json: { message: "Tax code discarded" }
  end

  private

  def tax_code_params
    params.require(:tax_code).permit(:name, :code, :kind, :description, :is_inclusive)
  end

  def tax_code_attributes
    attributes = tax_code_params.to_h
    raw_rate = params.dig(:tax_code, :rate_percent)
    return attributes if raw_rate.nil?

    raw = raw_rate.to_s.strip
    return attributes.merge("rate_bp" => 0) if raw.blank?
    return nil unless raw.match?(/\A\d+(\.\d+)?\z/)

    percent = BigDecimal(raw)
    return nil if percent.negative? || percent > 100

    attributes.merge("rate_bp" => (percent * 100).round)
  end

  def render_rate_error
    render json: { errors: [ "Tax rate must be a number between 0 and 100" ] },
      status: :unprocessable_content
  end

  def usage_counts(ids)
    return [ {}, {} ] if ids.empty?

    [
      current_company.products.where(tax_code_id: ids).group(:tax_code_id).count,
      current_company.services.where(tax_code_id: ids).group(:tax_code_id).count
    ]
  end

  def format_tax_code(code, product_counts = {}, service_counts = {})
    code.option_payload.merge(
      description: code.description,
      products_count: product_counts.fetch(code.id, 0),
      services_count: service_counts.fetch(code.id, 0)
    )
  end
end
