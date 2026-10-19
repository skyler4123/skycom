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

    if config.update(tax_config_params)
      respond_to do |format|
        format.html { redirect_to company_tax_path(current_company), notice: "Tax config updated" }
        format.json { render json: { tax_config: format_config(config) } }
      end
    else
      respond_to do |format|
        format.html { redirect_to company_tax_path(current_company), alert: config.errors.full_messages.to_sentence }
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
      excluded_invoice_statuses: [],
      excluded_purchase_statuses: [],
      stock_export_business_types: [],
      branch_ids: []
    )
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
      branch_ids: config.branch_ids
    }
  end
end
