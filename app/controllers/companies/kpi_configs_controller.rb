# app/controllers/companies/kpi_configs_controller.rb
#
# KPI rule configuration: Shell-First index plus JSON create/update/destroy.
# Authorization is ABAC through Companies::KpiConfigsPolicy (owner full access;
# Manager seeded read-only). Manager and other roles never receive config JSON
# unless the company grants the matching policy.
# Serves Stimulus: Companies_KpiConfigs_IndexController,
#                  Companies_KpiConfigs_NewModalController,
#                  Companies_KpiConfigs_EditModalController
# Endpoints: GET /companies/:company_id/kpi_configs(.json),
#            POST /companies/:company_id/kpi_configs,
#            PATCH/DELETE /companies/:company_id/kpi_configs/:id
# Docs: docs/KPI.md
class Companies::KpiConfigsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        render json: {
          kpi_configs: current_company.kpi_configs
            .includes(:category, :branch, :department, :role)
            .order(:name)
            .map { |config| format_kpi_config(config) },
          options: options_payload,
          can_manage: current_employee.can?(:create, KpiConfig)
        }
      end
    end
  end

  def create
    kpi_config = current_company.kpi_configs.new(kpi_config_params)

    if kpi_config.save
      render json: {
        kpi_config: format_kpi_config(kpi_config),
        message: "KPI created successfully"
      }, status: :created
    else
      render json: { errors: kpi_config.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    kpi_config = current_company.kpi_configs.find(params[:id])

    if kpi_config.update(kpi_config_params)
      render json: {
        kpi_config: format_kpi_config(kpi_config),
        message: "KPI updated successfully"
      }, status: :ok
    else
      render json: { errors: kpi_config.errors.full_messages }, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "KPI not found" ] }, status: :not_found
  end

  def destroy
    kpi_config = current_company.kpi_configs.find(params[:id])
    kpi_config.destroy!

    render json: { message: "KPI deleted successfully" }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "KPI not found" ] }, status: :not_found
  end

  private

  def kpi_config_params
    params.require(:kpi_config).permit(
      :name,
      :description,
      :metric_key,
      :direction,
      :period_type,
      :target_value,
      :weight,
      :category_id,
      :branch_id,
      :department_id,
      :role_id
    )
  end

  def format_kpi_config(config)
    config.as_json(only: [
      :id, :name, :description, :metric_key, :direction, :period_type,
      :target_value, :weight, :category_id, :branch_id, :department_id, :role_id,
      :workflow_status
    ]).merge(
      unit: config.metric&.unit,
      category: config.category&.as_json(only: [ :id, :name ]),
      branch: config.branch&.as_json(only: [ :id, :name ]),
      department: config.department&.as_json(only: [ :id, :name ]),
      role: config.role&.as_json(only: [ :id, :name ])
    )
  end

  def options_payload
    {
      metrics: Kpi::Metrics.catalog,
      categories: option_list(current_company.categories),
      branches: option_list(current_company.branches),
      departments: option_list(current_company.departments),
      roles: option_list(current_company.roles)
    }
  end

  def option_list(scope)
    scope.order(:name).pluck(:id, :name).map { |id, name| { id: id, name: name } }
  end
end
