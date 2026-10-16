# app/controllers/companies/company_settings_controller.rb
# Serves Stimulus: companies/settings/index_controller.js
#   (GET /companies/:id/company_settings, PATCH /companies/:id/company_settings/:id
#    for the company sidebar editor)
# Endpoints: index (Shell-First JSON), update (company setting JSON).
#   Shell for company settings — the sidebar editor lives on the index page.
# Docs: docs/SIDEBAR.md
class Companies::CompanySettingsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        settings = current_company.company_settings.order(:created_at).map(&:as_json)
        render json: { company_settings: settings }
      end
    end
  end

  def update
    setting = current_company.company_settings.find(params[:id])

    respond_to do |format|
      if setting.update(update_attributes)
        format.html do
          redirect_to company_company_settings_path(current_company),
            notice: "Company setting updated successfully"
        end
        format.json do
          render json: { company_setting: setting.as_json, message: "Company setting updated successfully" }
        end
      else
        format.html do
          redirect_to company_company_settings_path(current_company),
            alert: setting.errors.full_messages.to_sentence
        end
        format.json do
          render json: { errors: setting.errors.full_messages }, status: :unprocessable_content
        end
      end
    end
  end

  private

  def update_attributes
    attrs = {}
    params_source = params[:company_setting] || params[:setting] || {}
    attrs[:name] = params_source[:name] if params_source.key?(:name)
        attrs[:description] = params_source[:description] if params_source.key?(:description)
        attrs[:workflow_status] = params_source[:workflow_status] if params_source.key?(:workflow_status)

    metadata = params_source[:metadata]
    metadata = metadata.to_unsafe_h if metadata.is_a?(ActionController::Parameters)
    if metadata.is_a?(Hash)
      if metadata.key?("sidebar_groups") || metadata.key?(:sidebar_groups)
        attrs[:sidebar_groups] = normalize_sidebar_groups(metadata)
      else
        attrs[:metadata] = metadata
      end
    end

    attrs
  end

  # Whitelist name/key/url only; HTML forms send the groups array as a
  # {"0" => {...}} hash (see docs/DASHBOARD_PATTERN.md JSONB array pattern).
  def normalize_sidebar_groups(metadata)
    raw = metadata["sidebar_groups"] || metadata[:sidebar_groups]
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
