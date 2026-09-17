# app/controllers/companies/suppliers_controller.rb
#
# Suppliers dashboard API (Shell-First). index supports the same TableConfig-driven
# dynamic search/filter as Brands (?q= / ?filters[key]= → Meilisearch via
# Suppliers::SearchQueryService; plain DB path otherwise).
# Serves Stimulus: Companies_Suppliers_IndexController (index JSON incl. q/filters passthrough),
#                  Companies_Suppliers_NewController|ShowController|EditController
# Endpoints: GET /companies/:company_id/suppliers(.json) + nested CRUD — see config/routes.rb
# Docs: docs/DYNAMIC_TABLE.md §2.5, docs/MEILISEARCH.md
class Companies::SuppliersController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.suppliers
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        search = Suppliers::SearchQueryService.new(company: current_company, params: params)
        scope = scope.where(id: search.record_ids).in_order_of(:id, search.record_ids) if search.active?

        @pagy, @suppliers_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          suppliers: format_suppliers(@suppliers_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    supplier = current_company.suppliers.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { supplier: format_supplier(supplier) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    supplier = current_company.suppliers.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { supplier: format_supplier(supplier) } }
    end
  end

  def create
    supplier = current_company.suppliers.new(supplier_params)
    supplier.code ||= "SU-#{SecureRandom.hex(4).upcase}"
    if supplier.save
      redirect_to company_supplier_path(current_company, supplier), notice: "Supplier created successfully"
    else
      redirect_to new_company_supplier_path(current_company),
        alert: supplier.errors.full_messages.to_sentence
    end
  end

  def update
    supplier = current_company.suppliers.find(params[:id])

    respond_to do |format|
      format.html do
        if supplier.update(supplier_params)
          redirect_to company_supplier_path(current_company, supplier), notice: "Supplier updated successfully."
        else
          redirect_to edit_company_supplier_path(current_company, supplier),
            alert: supplier.errors.full_messages.to_sentence
        end
      end
      format.json do
        if supplier.update(supplier_params)
          render json: { supplier: format_supplier(supplier), message: "Supplier updated successfully" }, status: :ok
        else
          render json: { errors: supplier.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Supplier not found" }, status: :not_found
  end

  private

  def property_keys
    (1..10).map { |i| "property_string_#{i}" } +
      (1..20).map { |i| "property_integer_#{i}" } +
      (1..10).map { |i| "property_decimal_#{i}" } +
      (1..10).map { |i| "property_boolean_#{i}" } +
      (1..10).map { |i| "property_datetime_#{i}" }
  end

  def supplier_params
    params.require(:supplier).permit(
      :name,
      :description,
      :code,
      :business_type,
      :workflow_status,
      :category_id,
      :phone_number,
      :email,
      *property_keys
    )
  end

  def format_supplier(supplier)
    supplier.as_json(only: [
      :id, :name, :description, :code, :category_id,
      :business_type, :lifecycle_status, :workflow_status,
      :phone_number, :email,
      :created_at, :updated_at,
      :property_string_1, :property_string_2, :property_string_3, :property_string_4, :property_string_5,
      :property_string_6, :property_string_7, :property_string_8, :property_string_9, :property_string_10,
      :property_integer_1, :property_integer_2, :property_integer_3, :property_integer_4, :property_integer_5,
      :property_integer_6, :property_integer_7, :property_integer_8, :property_integer_9, :property_integer_10,
      :property_integer_11, :property_integer_12, :property_integer_13, :property_integer_14, :property_integer_15,
      :property_integer_16, :property_integer_17, :property_integer_18, :property_integer_19, :property_integer_20,
      :property_decimal_1, :property_decimal_2, :property_decimal_3, :property_decimal_4, :property_decimal_5,
      :property_decimal_6, :property_decimal_7, :property_decimal_8, :property_decimal_9, :property_decimal_10,
      :property_boolean_1, :property_boolean_2, :property_boolean_3, :property_boolean_4, :property_boolean_5,
      :property_boolean_6, :property_boolean_7, :property_boolean_8, :property_boolean_9, :property_boolean_10,
      :property_datetime_1, :property_datetime_2, :property_datetime_3, :property_datetime_4, :property_datetime_5,
      :property_datetime_6, :property_datetime_7, :property_datetime_8, :property_datetime_9, :property_datetime_10
    ]).merge(
      category: supplier.category&.as_json(only: [ :id, :name ])
    )
  end

  def format_suppliers(suppliers)
    suppliers.map { |supplier| format_supplier(supplier) }
  end
end
