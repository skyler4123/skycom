# app/controllers/companies/customer_subprofiles_controller.rb
#
# CustomerSubprofiles dashboard API (Shell-First).
# Serves Stimulus: Companies_CustomerSubprofiles_IndexController,
#                  Companies_CustomerSubprofiles_NewController|ShowController|EditController
# Endpoints: GET /companies/:company_id/customer_subprofiles(.json) + nested CRUD — see config/routes.rb
# Docs: docs/DYNAMIC_TABLE.md §2.5, docs/MEILISEARCH.md
class Companies::CustomerSubprofilesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.customer_subprofiles.kept.includes(:customer, :customer_profile)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        scope = scope.where(branch_id: params[:branch_id]) if params[:branch_id].present?
        scope = scope.where(customer_id: params[:customer_id]) if params[:customer_id].present?
        scope = scope.where(customer_profile_id: params[:customer_profile_id]) if params[:customer_profile_id].present?

        search = CustomerSubprofiles::SearchQueryService.new(company: current_company, params: params)
        scope = scope.where(id: search.record_ids).in_order_of(:id, search.record_ids) if search.active?

        @pagy, @results = pagy(:offset, scope, jsonapi: true)

        render json: {
          customer_subprofiles: format_collection(@results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    record = current_company.customer_subprofiles.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { customer_subprofile: format_record(record) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    record = current_company.customer_subprofiles.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { customer_subprofile: format_record(record) } }
    end
  end

  def create
    record = current_company.customer_subprofiles.new(record_params)
    record.code ||= "CS-#{SecureRandom.hex(4).upcase}"
    if record.save
      redirect_to company_customer_subprofile_path(current_company, record), notice: "Customer subprofile created successfully"
    else
      redirect_to new_company_customer_subprofile_path(current_company),
        alert: record.errors.full_messages.to_sentence
    end
  end

  def update
    record = current_company.customer_subprofiles.find(params[:id])

    respond_to do |format|
      format.html do
        if record.update(record_params)
          redirect_to company_customer_subprofile_path(current_company, record), notice: "Customer subprofile updated successfully."
        else
          redirect_to edit_company_customer_subprofile_path(current_company, record),
            alert: record.errors.full_messages.to_sentence
        end
      end
      format.json do
        if record.update(record_params)
          render json: { customer_subprofile: format_record(record), message: "Customer subprofile updated successfully" }, status: :ok
        else
          render json: { errors: record.errors.full_messages }, status: :unprocessable_content
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Customer subprofile not found" }, status: :not_found
  end

  def destroy
    record = current_company.customer_subprofiles.find(params[:id])

    respond_to do |format|
      format.json do
        if record.discard!
          render json: { message: "Customer subprofile deleted successfully!" }
        else
          render json: { errors: record.errors.full_messages }, status: :unprocessable_content
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Customer subprofile not found" }, status: :not_found
  rescue Discard::RecordNotDiscarded => e
    render json: { errors: [ e.message ] }, status: :unprocessable_content
  end

  private

  def property_keys
    (1..5).map { |i| "property_string_#{i}" } +
      (1..10).map { |i| "property_integer_#{i}" } +
      (1..5).map { |i| "property_decimal_#{i}" } +
      (1..5).map { |i| "property_boolean_#{i}" } +
      (1..5).map { |i| "property_datetime_#{i}" }
  end

  def record_params
    params.require(:customer_subprofile).permit(
      :name, :description, :code, :business_type, :workflow_status,
      :category_id, :branch_id, :customer_id, :customer_profile_id, :phone_number, :email,
      *property_keys
    )
  end

  def format_record(record)
    record.as_json(only: [
      :id, :name, :description, :code, :category_id, :branch_id, :customer_id, :customer_profile_id,
      :business_type, :lifecycle_status, :workflow_status,
      :phone_number, :email, :created_at, :updated_at,
      :property_string_1, :property_string_2, :property_string_3, :property_string_4, :property_string_5,
      :property_integer_1, :property_integer_2, :property_integer_3, :property_integer_4, :property_integer_5,
      :property_integer_6, :property_integer_7, :property_integer_8, :property_integer_9, :property_integer_10,
      :property_decimal_1, :property_decimal_2, :property_decimal_3, :property_decimal_4, :property_decimal_5,
      :property_boolean_1, :property_boolean_2, :property_boolean_3, :property_boolean_4, :property_boolean_5,
      :property_datetime_1, :property_datetime_2, :property_datetime_3, :property_datetime_4, :property_datetime_5,
    ]).merge(
      category: record.category&.as_json(only: [ :id, :name ]),
      customer: record.customer&.as_json(only: [ :id, :name ])
    )
  end

  def format_collection(records)
    records.map { |r| format_record(r) }
  end
end
