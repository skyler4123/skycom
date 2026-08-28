# app/controllers/companies/settings_controller.rb
# Serves Stimulus: companies/settings/index_controller.js (GET /companies/:id/settings)
#                   companies/settings/tabs/sidebar_controller.js (PATCH /companies/:id/settings/:id)
# Endpoints: index (Shell-First JSON), update (JSON PATCH)
class Companies::SettingsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        settings = current_company.settings.company_level.order(:created_at).map(&:as_json)
        render json: { settings: settings }
      end
    end
  end

  def update
    setting = current_company.settings.find(params[:id])

    if setting.update(setting_params)
      render json: { setting: setting.as_json, message: "Settings updated" }, status: :ok
    else
      render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "Setting not found" ] }, status: :not_found
  end

  private

  def setting_params
    params.require(:setting).permit(sidebar_items: [ :key, :visible ])
  end
end
