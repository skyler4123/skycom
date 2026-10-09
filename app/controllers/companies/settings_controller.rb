# app/controllers/companies/settings_controller.rb
# Serves Stimulus: companies/settings/index_controller.js
#   (GET /companies/:id/settings, PATCH /companies/:id/settings/:id for the dynamic sidebar)
# Endpoints: index (Shell-First JSON), update (dynamic sidebar metadata JSON).
#   Shell for company settings — the dynamic sidebar editor lives on the index page.
# Docs: docs/SIDEBAR.md
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
    setting = current_company.settings.company_level.find(params[:id])

    respond_to do |format|
      if setting.update(sidebar_groups: normalize_sidebar_groups)
        format.html do
          redirect_to company_settings_path(current_company),
            notice: "Dynamic sidebar updated successfully"
        end
        format.json do
          render json: { setting: setting.as_json, message: "Dynamic sidebar updated successfully" }
        end
      else
        format.html do
          redirect_to company_settings_path(current_company),
            alert: setting.errors.full_messages.to_sentence
        end
        format.json do
          render json: { errors: setting.errors.full_messages }, status: :unprocessable_content
        end
      end
    end
  end

  private

  # Whitelist name/key/url only; HTML forms send the groups array as a
  # {"0" => {...}} hash (see docs/DASHBOARD_PATTERN.md JSONB array pattern).
  def normalize_sidebar_groups
    metadata = params.require(:setting)[:metadata]
    metadata = metadata.to_unsafe_h if metadata.is_a?(ActionController::Parameters)
    raw = metadata.is_a?(Hash) ? (metadata["sidebar_groups"] || metadata[:sidebar_groups]) : nil
    raw = raw.values if raw.is_a?(Hash)
    return [] if raw.nil?
    return raw unless raw.is_a?(Array)

    raw.map do |group|
      next unless group.is_a?(Hash)
      g = group.with_indifferent_access
      items_raw = g[:items]
      items_raw = items_raw.values if items_raw.is_a?(Hash)
      items = items_raw.is_a?(Array) ? items_raw.map do |item|
        next unless item.is_a?(Hash)
        i = item.with_indifferent_access
        { "key" => i[:key].to_s, "name" => i[:name].to_s, "url" => i[:url].to_s }
      end.compact : []
      { "key" => g[:key].to_s, "name" => g[:name].to_s, "items" => items }
    end.compact
  end
end
