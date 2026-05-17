# app/controllers/companies/branches_controller.rb

class Companies::BranchesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.branches
        scope = scope.where(business_type: params[:business_type]) if params[:business_type].present?
        scope = scope.where(workflow_status: params[:workflow_status]) if params[:workflow_status].present?

        @pagy, @branches_results = pagy(:offset, scope, jsonapi: true)

        render json: {
          branches: format_branches(@branches_results),
          pagination: @pagy.data_hash
        }
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        branch = current_company.branches.new(branch_params)
        if branch.save
          render json: { branch: format_branch(branch) }, status: :created
        else
          render json: { errors: branch.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    branch = current_company.branches.find(params[:id])

    respond_to do |format|
      format.json do
        if branch.update(branch_params)
          render json: { branch: format_branch(branch) }, status: :created
        else
          render json: { errors: branch.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Branch not found" }, status: :not_found
  end

  private

  def branch_params
    params.require(:branch).permit(
      :name,
      :description,
      :business_type,
      :workflow_status,
      :country_code,
      :phone_number,
      :email
    )
  end

  def format_branch(branch)
    result = {
      id: branch.id,
      name: branch.name,
      description: branch.description,
      code: branch.code,
      business_type: branch.business_type,
      lifecycle_status: branch.lifecycle_status,
      workflow_status: branch.workflow_status,
      country_code: branch.country_code,
      phone_number: branch.phone_number,
      email: branch.email,
      created_at: branch.created_at,
      updated_at: branch.updated_at
    }
    result[:address] = branch.address.as_json(only: [ :line_1, :line_2, :city, :state_or_province, :postal_code, :country_code ]) if branch.address
    result
  end

  def format_branches(branches)
    branches.map { |branch| format_branch(branch) }
  end
end
