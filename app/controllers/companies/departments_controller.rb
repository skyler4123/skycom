# app/controllers/companies/departments_controller.rb

class Companies::DepartmentsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.departments
        scope = scope.where(business_type: params[:business_type]) if params[:business_type].present?
        scope = scope.where(workflow_status: params[:workflow_status]) if params[:workflow_status].present?

        @pagy, @departments_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          departments: format_departments(@departments_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        department = current_company.departments.new(department_params)
        if department.save
          render json: { department: format_department(department) }, status: :created
        else
          render json: { errors: department.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    department = current_company.departments.find(params[:id])

    respond_to do |format|
      format.json do
        if department.update(department_params)
          render json: { department: format_department(department) }, status: :created
        else
          render json: { errors: department.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Department not found" }, status: :not_found
  end

  private

  def department_params
    params.require(:department).permit(
      :name,
      :description,
      :business_type,
      :workflow_status
    )
  end

  def format_department(department)
    department.as_json(only: [
      :id, :name, :description, :code,
      :lifecycle_status, :workflow_status, :business_type,
      :created_at, :updated_at
    ])
  end

  def format_departments(departments)
    departments.map { |department| format_department(department) }
  end
end
