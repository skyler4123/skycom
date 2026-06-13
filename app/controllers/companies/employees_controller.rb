class Companies::EmployeesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.employees.kept.includes(:user, :branch)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

        @pagy, @employees_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          employees: format_employees(@employees_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def show
    employee = current_company.employees.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { employee: format_employee(employee) } }
    end
  end

  def new
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: {} }
    end
  end

  def edit
    employee = current_company.employees.find(params[:id])

    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { employee: format_employee(employee) } }
    end
  end

  def create
    employee = current_company.employees.new(create_employee_params)

    if employee.save
      redirect_to company_employee_path(current_company, employee), notice: "Employee created successfully."
    else
      redirect_to new_company_employee_path(current_company),
        alert: employee.errors.full_messages.to_sentence
    end
  end

  def update
    employee = current_company.employees.find(params[:id])

    if employee.update(update_employee_params)
      redirect_to company_employee_path(current_company, employee), notice: "Employee updated successfully."
    else
      redirect_to edit_company_employee_path(current_company, employee),
        alert: employee.errors.full_messages.to_sentence
    end
  end

  def destroy
    employee = current_company.employees.find(params[:id])

    respond_to do |format|
      format.json do
        if employee.discard!
          render json: { message: "Employee deleted successfully!" }
        else
          render json: { errors: employee.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Employee not found" }, status: :not_found
  rescue Discard::RecordNotDiscarded => e
    render json: { errors: [ e.message ] }, status: :unprocessable_entity
  end

  private

  def create_employee_params
    property_keys = (1..10).map { |i| "property_string_#{i}" } +
                    (1..5).map { |i| "property_text_#{i}" } +
                    (1..20).map { |i| "property_integer_#{i}" } +
                    (1..10).map { |i| "property_decimal_#{i}" } +
                    (1..10).map { |i| "property_boolean_#{i}" } +
                    (1..10).map { |i| "property_datetime_#{i}" }

    params.require(:employee).permit(
      :name,
      :description,
      :business_type,
      :branch_id,
      :workflow_status,
      :category_id,
      *property_keys
    )
  end

  def update_employee_params
    property_keys = (1..10).map { |i| "property_string_#{i}" } +
                    (1..5).map { |i| "property_text_#{i}" } +
                    (1..20).map { |i| "property_integer_#{i}" } +
                    (1..10).map { |i| "property_decimal_#{i}" } +
                    (1..10).map { |i| "property_boolean_#{i}" } +
                    (1..10).map { |i| "property_datetime_#{i}" }

    params.require(:employee).permit(
      :name,
      :description,
      :business_type,
      :branch_id,
      :workflow_status,
      :category_id,
      *property_keys
    )
  end

  def format_employee(employee)
    employee.as_json(only: [
      :id, :name, :description, :code, :branch_id, :category_id,
      :business_type, :lifecycle_status, :workflow_status, :phone_number,
      :email, :created_at, :updated_at,
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
      user: employee.user&.as_json(only: [ :id, :email ]),
      branch: employee.branch&.as_json(only: [ :id, :name ]),
      category: employee.category&.as_json(only: [ :id, :name ]),
      roles: employee.roles.map { |r| { id: r.id, name: r.name } },
      departments: employee.departments.map { |d| { id: d.id, name: d.name } }
    )
  end

  def format_employees(employees)
    employees.map { |employee| format_employee(employee) }
  end
end
