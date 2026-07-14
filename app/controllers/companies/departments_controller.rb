# app/controllers/companies/departments_controller.rb

class Companies::DepartmentsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.departments
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @departments_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          departments: format_departments(@departments_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    department = current_company.departments.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { department: format_department(department) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    department = current_company.departments.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { department: format_department(department) } }
    end
  end

  def create
    department = current_company.departments.new(department_params)
    if department.save
      redirect_to company_department_path(current_company, department), notice: "Department created successfully"
    else
      redirect_to new_company_department_path(current_company),
        alert: department.errors.full_messages.to_sentence
    end
  end

  def update
    department = current_company.departments.find(params[:id])

    respond_to do |format|
      format.html do
        if department.update(department_params)
          redirect_to company_department_path(current_company, department), notice: "Department updated successfully."
        else
          redirect_to edit_company_department_path(current_company, department),
            alert: department.errors.full_messages.to_sentence
        end
      end
      format.json do
        if department.update(department_params)
          render json: { department: format_department(department), message: "Department updated successfully" }, status: :ok
        else
          render json: { errors: department.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Department not found" }, status: :not_found
  end

  private

  def property_keys
    (1..10).map { |i| "property_string_#{i}" } +
      (1..5).map { |i| "property_text_#{i}" } +
      (1..20).map { |i| "property_integer_#{i}" } +
      (1..10).map { |i| "property_decimal_#{i}" } +
      (1..10).map { |i| "property_boolean_#{i}" } +
      (1..10).map { |i| "property_datetime_#{i}" }
  end

  def department_params
    params.require(:department).permit(
      :name,
      :description,
      :business_type,
      :workflow_status,
      :email,
      :category_id,
      *property_keys
    )
  end

  def format_department(department)
    department.as_json(only: [
      :id, :name, :description, :code, :category_id,
      :business_type, :lifecycle_status, :workflow_status,
      :created_at, :updated_at,
      :property_string_1, :property_string_2, :property_string_3, :property_string_4, :property_string_5,
      :property_string_6, :property_string_7, :property_string_8, :property_string_9, :property_string_10,
      :property_text_1, :property_text_2, :property_text_3, :property_text_4, :property_text_5,
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
      category: department.category&.as_json(only: [ :id, :name ])
    )
  end

  def format_departments(departments)
    departments.map { |department| format_department(department) }
  end
end
