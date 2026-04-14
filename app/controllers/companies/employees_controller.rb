# app/controllers/companies/employees_controller.rb

class Companies::EmployeesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        # 1. Apply Filtering Logic
        scope = current_company.employees.includes(:user, :roles, :departments, :branch)
        scope = scope.where(departments: { id: params[:department_id] }) if params[:department_id].present?
        scope = scope.where(roles: { id: params[:role_id] }) if params[:role_id].present?
        scope = scope.where(business_type: params[:business_type]) if params[:business_type].present?
        scope = scope.where(workflow_status: params[:workflow_status]) if params[:workflow_status].present?

        @pagy, @employees_results = pagy(:offset, scope, jsonapi: true)
        # 2. Always provide filter options so the form stays populated
        # filter_options = {
        #   departments: current_company.departments.map { |d| { name: d.name, value: d.id} },
        #   roles: current_company.roles.map { |r| { name: r.name, value: r.id } },
        #   statuses: Employee.lifecycle_statuses.keys.map { |s| { name: s.humanize, value: s } },
        #   types: Employee.business_types.keys.map { |t| { name: t.humanize, value: t } }
        # }

        render json: {
          employees: format_employees(@employees_results),
          pagination: @pagy.data_hash
          # filter_options: filter_options
        }
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        begin
          # Using your Seed::EmployeeService to handle the creation logic
          @employee = Seed::EmployeeService.create(
            company: current_company,
            name: employee_params[:name],
            description: employee_params[:description],
            business_type: employee_params[:business_type],
            # Optionally pass branch or user if provided in params
            branch: current_company.branches.find_by(id: employee_params[:branch_id]),
            departments: current_company.departments.where(id: employee_params[:department_id]),
            roles: current_company.roles.where(id: employee_params[:role_id]),
            user: User.find_by(id: params[:user_id])
          )

          render json: {
            status: "success",
            message: "Employee created successfully.",
            employee: format_single_employee(@employee)
          }, status: :created

        rescue ActiveRecord::RecordInvalid => e
          render json: {
            status: "error",
            message: "Validation failed",
            errors: e.record.errors.full_messages
          }, status: :unprocessable_entity
        rescue => e
          render json: {
            status: "error",
            message: e.message
          }, status: :internal_server_error
        end
      end
    end
  end

  def update
    @employee = current_company.employees.find(params[:id])

    respond_to do |format|
      format.json do
        update_params = update_employee_params
        if update_params[:role_ids]
          @employee.role_ids = update_params.delete(:role_ids)
        end
        if @employee.update(update_params)
          render json: {
            status: "success",
            message: "Updated successfully",
            employee: format_single_employee(@employee)
          }
        else
          render json: {
            status: "error",
            errors: @employee.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Employee not found" }, status: :not_found
  end

  private

  def employee_params
    params.require(:employee).permit(:name, :description, :business_type, :branch_id, :department_id, :role_id)
  end

  def update_employee_params
    params.permit(
      :name,
      :description,
      :business_type,
      :branch_id,
      :department_id,
      :workflow_status,
      role_ids: []
    )
  end

  # Helper to format a single employee response, following your index pattern
  def format_single_employee(employee)
    employee.as_json(include: {
      user: { only: :email },
      branch: { only: [ :id, :name ] }
    }).merge(
      roles: employee.roles.map { |r| { id: r.id, name: r.name } },
      departments: employee.departments.map { |d| { id: d.id, name: d.name } }
    )
  end

  def format_employees(employees)
    employees.map do |employee|
      employee.as_json(include: { user: { only: :email }, branch: { only: [ :id, :name ] } }).merge(
        roles: employee.roles.map { |r| { id: r.id, name: r.name } },
        departments: employee.departments.map { |d| { id: d.id, name: d.name } }
      )
    end
  end
end
