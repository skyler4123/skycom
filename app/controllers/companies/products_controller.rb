# app/controllers/companies/products_controller.rb
#
# Products dashboard API (Shell-First: HTML shell + JSON for Stimulus hydration).
# index: plain DB list, OR Meilisearch-backed when ?q= / ?filters[key]= params are
#        present AND the category's TableConfig enables search/filter per column
#        (whitelist + query building live in Products::SearchQueryService).
#        List rows add brand, cost, unit, and stock_quantity = SUM(stocks.quantity)
#        (branch-scoped when ?branch_id= is present).
# Serves Stimulus: Companies_Products_IndexController (index JSON incl. q/filters/export passthrough),
#                  Companies_Products_NewController|ShowController|EditController (record JSON + form mutations)
# Endpoints: GET /companies/:company_id/products(.json), GET /companies/:company_id/products/:id(.json with stocks) + nested CRUD — see config/routes.rb
# Docs: docs/DYNAMIC_TABLE.md, docs/MEILISEARCH.md

class Companies::ProductsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.products.includes(:category, :tax_code, :brand)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?

        search = Products::SearchQueryService.new(company: current_company, params: params)
        scope = scope.where(id: search.record_ids).in_order_of(:id, search.record_ids) if search.active?

        if params[:export].present?
          results = scope.to_a
          if results.size > EXPORT_MAX_RECORDS
            render json: { errors: [ "Export exceeds maximum of #{EXPORT_MAX_RECORDS} records" ] }, status: :unprocessable_content and return
          end
          render json: { products: format_products(results) } and return
        end

        @pagy, @products_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          products: format_products(@products_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    product = current_company.products.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          product: format_product(product),
          stocks: product_stocks(product).map { |s| format_stock(s) },
          effective_tax_code: TaxCodes::Resolver.call(record: product)&.option_payload,
          uses_default_tax: product.tax_code.nil? || product.tax_code.discarded?
        }
      end
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          tax_codes: tax_code_options,
          default_tax_code: TaxConfig.for_company!(current_company).default_tax_code&.option_payload
        }
      end
    end
  end

  def edit
    product = current_company.products.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          product: format_product(product),
          tax_codes: tax_code_options,
          default_tax_code: TaxConfig.for_company!(current_company).default_tax_code&.option_payload,
          effective_tax_code: TaxCodes::Resolver.call(record: product)&.option_payload,
          uses_default_tax: product.tax_code.nil? || product.tax_code.discarded?
        }
      end
    end
  end

  def create
    product = current_company.products.new(product_params)
    if product.save
      redirect_to company_product_path(current_company, product), notice: "Product created successfully"
    else
      redirect_to new_company_product_path(current_company),
        alert: product.errors.full_messages.to_sentence
    end
  end

  def update
    product = current_company.products.find(params[:id])

    respond_to do |format|
      format.html do
        if product.update(product_params)
          redirect_to company_product_path(current_company, product), notice: "Product updated successfully."
        else
          redirect_to edit_company_product_path(current_company, product),
            alert: product.errors.full_messages.to_sentence
        end
      end
      format.json do
        if product.update(product_params)
          render json: { product: format_product(product), message: "Product updated successfully" }, status: :ok
        else
          render json: { errors: product.errors.full_messages }, status: :unprocessable_content
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Product not found" }, status: :not_found
  end

  private

  def product_params
    property_keys = (1..5).map { |i| "property_string_#{i}" } +
                    (1..10).map { |i| "property_integer_#{i}" } +
                    (1..5).map { |i| "property_decimal_#{i}" } +
                    (1..5).map { |i| "property_boolean_#{i}" } +
                    (1..5).map { |i| "property_datetime_#{i}" }

    params.require(:product).permit(
      :name, :description, :business_type, :workflow_status, :category_id,
      :price_cents, :currency, :tax_code_id,
      *property_keys
    )
  end

  def format_product(product)
    product.as_json(only: [
      :id, :name, :description, :code, :category_id, :tax_code_id, :brand_id,
      :lifecycle_status, :workflow_status, :business_type,
      :created_at, :updated_at,
      :price_cents, :cost_cents, :currency, :unit_of_measure,
      :property_string_1, :property_string_2, :property_string_3, :property_string_4, :property_string_5,
      :property_integer_1, :property_integer_2, :property_integer_3, :property_integer_4, :property_integer_5,
      :property_integer_6, :property_integer_7, :property_integer_8, :property_integer_9, :property_integer_10,
      :property_decimal_1, :property_decimal_2, :property_decimal_3, :property_decimal_4, :property_decimal_5,
      :property_boolean_1, :property_boolean_2, :property_boolean_3, :property_boolean_4, :property_boolean_5,
      :property_datetime_1, :property_datetime_2, :property_datetime_3, :property_datetime_4, :property_datetime_5
    ]).merge(
      category: product.category&.as_json(only: [ :id, :name ]),
      brand: product.brand&.as_json(only: [ :id, :name ]),
      tax_code: product.tax_code&.option_payload
    )
  end

  def tax_code_options
    current_company.tax_codes.kept.ordered.map(&:option_payload)
  end

  def format_products(products)
    stock_quantities = stock_quantities_for(products)
    products.map do |product|
      format_product(product).merge(stock_quantity: stock_quantities[product.id])
    end
  end

  # Physical on-hand units across warehouses, narrowed to the selected branch.
  # Missing stock rows stay nil so the table can render an honest "—".
  def stock_quantities_for(products)
    product_ids = products.map(&:id)
    return {} if product_ids.empty?

    scope = current_company.stocks.where(product_id: product_ids)
    scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?
    scope.group(:product_id).sum(:quantity)
  end

  def product_stocks(product)
    current_company.stocks.includes(:product, :warehouse)
      .where(product_id: product.id)
      .joins(:warehouse).order("warehouses.name ASC")
  end

  def format_stock(stock)
    stock.as_json(only: %i[id quantity pending]).merge(
      available: [ stock.quantity.to_i - stock.pending.to_i, 0 ].max,
      product: stock.product&.as_json(only: %i[id name]),
      warehouse: stock.warehouse&.as_json(only: %i[id name])
    )
  end
end
