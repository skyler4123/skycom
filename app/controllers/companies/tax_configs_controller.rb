# frozen_string_literal: true

# Companies::TaxConfigsController — company-level tax rebuild configuration.
# Serves Stimulus: Companies_TaxConfigs_ShowController (if used) and Tax page settings.
# Endpoints: GET/PATCH /companies/:company_id/tax_config(.json)
class Companies::TaxConfigsController < Companies::ApplicationController
  def show
    config = TaxConfig.for_company!(current_company)

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { tax_config: format_config(config) } }
    end
  end

  def update
    config = TaxConfig.for_company!(current_company)
    attributes = normalized_tax_config_params
    return render_tax_rate_error unless attributes

    if config.update(attributes)
      respond_to do |format|
        format.html { redirect_to company_tax_config_path(current_company), notice: "Tax config updated" }
        format.json { render json: { tax_config: format_config(config) } }
      end
    else
      respond_to do |format|
        format.html { redirect_to company_tax_config_path(current_company), alert: config.errors.full_messages.to_sentence }
        format.json { render json: { errors: config.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  private

  def tax_config_params
    params.require(:tax_config).permit(
      :date_basis,
      :include_invoices,
      :include_purchases,
      :include_stock_exports,
      :pos_tax_rate_percent,
      :pos_tax_name,
      excluded_invoice_statuses: [],
      excluded_purchase_statuses: [],
      stock_export_business_types: [],
      branch_ids: []
    )
  end

  # The UI talks in percent because that is what a manager reads; the model
  # stores basis points so money never touches a float.
  def normalized_tax_config_params
    attributes = tax_config_params.to_h
    return attributes unless attributes.key?("pos_tax_rate_percent")

    raw = attributes.delete("pos_tax_rate_percent").to_s.strip
    return attributes.merge("pos_tax_rate_bp" => 0) if raw.blank?
    return nil unless raw.match?(/\A\d+(\.\d+)?\z/)

    percent = BigDecimal(raw)
    return nil if percent.negative? || percent > 100

    attributes.merge("pos_tax_rate_bp" => (percent * 100).round)
  end

  def render_tax_rate_error
    respond_to do |format|
      format.html { redirect_to company_tax_config_path(current_company), alert: "Tax rate must be a number between 0 and 100" }
      format.json do
        render json: { errors: [ "Tax rate must be a number between 0 and 100" ] },
          status: :unprocessable_content
      end
    end
  end

  def format_config(config)
    {
      id: config.id,
      date_basis: config.date_basis,
      include_invoices: config.include_invoices,
      include_purchases: config.include_purchases,
      include_stock_exports: config.include_stock_exports,
      excluded_invoice_statuses: config.excluded_invoice_statuses,
      excluded_purchase_statuses: config.excluded_purchase_statuses,
      stock_export_business_types: config.stock_export_business_types,
      branch_ids: config.branch_ids,
      pos_tax_rate_bp: config.pos_tax_rate_bp.to_i,
      pos_tax_rate_percent: config.pos_tax_rate_percent,
      pos_tax_name: config.pos_tax_name.presence || "Tax"
    }
  end
end
