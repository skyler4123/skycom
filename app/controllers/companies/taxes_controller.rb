# frozen_string_literal: true

# Companies::TaxesController — raw tax-preparation data review (no tax calculation).
# Serves Stimulus: Companies_Taxes_IndexController
# Endpoints: GET /companies/:company_id/tax(.json) + summary/invoices/purchases/stock_exports
class Companies::TaxesController < Companies::ApplicationController
  ALLOWED_DATE_COLUMNS = {
    "Invoice" => %w[created_at updated_at due_date],
    "Purchase" => %w[created_at updated_at],
    "StockExport" => %w[created_at updated_at]
  }.freeze

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { tax_config: format_tax_config } }
    end
  end

  def summary
    config = TaxConfig.for_company!(current_company)
    from, to = period_range

    render json: {
      period: { from: from.to_s, to: to.to_s },
      tax_config: format_tax_config(config),
      summary: {
        invoices: invoice_summary(config, from, to),
        purchases: purchase_summary(config, from, to),
        stock_exports: stock_export_summary(config, from, to)
      }
    }
  end

  def invoices
    config = TaxConfig.for_company!(current_company)
    from, to = period_range
    scope = scoped_invoices(config, from, to)
    @pagy, results = pagy(:offset, scope, jsonapi: true)

    render json: {
      invoices: results.map { |invoice| format_invoice(invoice) },
      pagination: @pagy.data_hash
    }
  end

  def purchases
    config = TaxConfig.for_company!(current_company)
    from, to = period_range
    scope = scoped_purchases(config, from, to)
    @pagy, results = pagy(:offset, scope, jsonapi: true)

    render json: {
      purchases: results.map { |purchase| format_purchase(purchase) },
      pagination: @pagy.data_hash
    }
  end

  def stock_exports
    config = TaxConfig.for_company!(current_company)
    from, to = period_range
    scope = scoped_stock_exports(config, from, to)
    @pagy, results = pagy(:offset, scope, jsonapi: true)

    render json: {
      stock_exports: results.map { |export| format_stock_export(export) },
      pagination: @pagy.data_hash
    }
  end

  private

  def period_range
    from = parse_date(params[:from]) || Date.current.beginning_of_month
    to = parse_date(params[:to]) || Date.current.end_of_month
    from, to = to, from if from > to
    [ from, to ]
  end

  def parse_date(value)
    return nil if value.blank?
    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def date_column(model_name, requested)
    allowed = ALLOWED_DATE_COLUMNS[model_name] || %w[created_at]
    requested = requested.to_s
    allowed.include?(requested) ? requested : allowed.first
  end

  def branch_filter(scope, config)
    ids = Array(config.branch_ids).reject(&:blank?)
    ids.present? ? scope.where(branch_id: ids) : scope
  end

  # Inclusive [from, to] filter on a whitelisted column. Arel quotes the
  # identifier, so no SQL string is built from config values.
  def date_range_filter(scope, column, from, to)
    scope.where(scope.klass.arel_table[column].between(from.beginning_of_day..to.end_of_day))
  end

  def scoped_invoices(config, from, to)
    return current_company.invoices.none unless config.include_invoices
    col = date_column("Invoice", config.date_basis)
    scope = current_company.invoices.includes(:branch)
    scope = branch_filter(scope, config)
    excluded = Array(config.excluded_invoice_statuses).reject(&:blank?)
    scope = scope.where.not(payment_status: excluded) if excluded.present?
    date_range_filter(scope, col, from, to)
  end

  def scoped_purchases(config, from, to)
    return current_company.purchases.none unless config.include_purchases
    col = date_column("Purchase", config.date_basis)
    scope = current_company.purchases.includes(:branch, :supplier, :warehouse)
    scope = branch_filter(scope, config)
    excluded = Array(config.excluded_purchase_statuses).reject(&:blank?)
    scope = scope.where.not(workflow_status: excluded) if excluded.present?
    date_range_filter(scope, col, from, to)
  end

  def scoped_stock_exports(config, from, to)
    return current_company.stock_exports.none unless config.include_stock_exports
    col = date_column("StockExport", config.date_basis)
    scope = current_company.stock_exports.includes(:branch, :warehouse, :product)
    scope = branch_filter(scope, config)
    types = Array(config.stock_export_business_types).reject(&:blank?)
    scope = scope.where(business_type: types) if types.present?
    date_range_filter(scope, col, from, to)
  end

  def invoice_summary(config, from, to)
    scope = scoped_invoices(config, from, to)
    { count: scope.count, total_cents: scope.sum(:price_cents) }
  end

  def purchase_summary(config, from, to)
    scope = scoped_purchases(config, from, to)
    total = scope.sum { |purchase| purchase.total_price.to_f }
    { count: scope.count, total_amount: total }
  end

  def stock_export_summary(config, from, to)
    scope = scoped_stock_exports(config, from, to)
    count = scope.count
    quantity = scope.joins(:stock_export_stock_appointments).sum("stock_export_stock_appointments.quantity")
    { count: count, total_quantity: quantity }
  end

  def format_tax_config(config = nil)
    config ||= TaxConfig.for_company!(current_company)
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

  def format_invoice(invoice)
    invoice.as_json(only: [ :id, :code, :payment_status, :price_cents, :currency, :branch_id, :created_at, :updated_at, :due_date ]).merge(
      branch: invoice.branch&.as_json(only: [ :id, :name ])
    )
  end

  def format_purchase(purchase)
    {
      id: purchase.id,
      code: purchase.code,
      name: purchase.name,
      workflow_status: purchase.workflow_status,
      total_price: purchase.total_price,
      supplier: purchase.supplier&.as_json(only: [ :id, :name ]),
      branch: purchase.branch&.as_json(only: [ :id, :name ]),
      warehouse: purchase.warehouse&.as_json(only: [ :id, :name ]),
      created_at: purchase.created_at,
      updated_at: purchase.updated_at
    }
  end

  def format_stock_export(stock_export)
    {
      id: stock_export.id,
      code: stock_export.code,
      name: stock_export.name,
      business_type: stock_export.business_type,
      quantity: stock_export.stock_export_stock_appointments.sum(:quantity),
      branch: stock_export.branch&.as_json(only: [ :id, :name ]),
      warehouse: stock_export.warehouse&.as_json(only: [ :id, :name ]),
      created_at: stock_export.created_at,
      updated_at: stock_export.updated_at
    }
  end
end
