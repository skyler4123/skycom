# app/controllers/companies/settings_controller.rb
# Serves Stimulus: companies/settings/index_controller.js (GET /companies/:id/settings)
# Endpoints: index (Shell-First JSON). Shell for future settings — sidebar
# configuration is FE-only (localStorage favourites, see docs/SIDEBAR.md).
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
end
