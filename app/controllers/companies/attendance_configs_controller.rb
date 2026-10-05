# app/controllers/companies/attendance_configs_controller.rb
#
# AttendanceConfig dashboard API (Shell-First). Per-branch geofence + resolution
# config: GPS coordinates, allowed radius/WiFi, photo requirement, and the
# check-in resolution strategy.
# Serves Stimulus: Companies_AttendanceConfigs_IndexController,
#                  Companies_AttendanceConfigs_NewController|ShowController|EditController
# Endpoints: GET /companies/:company_id/attendance_configs(.json) + nested CRUD — see config/routes.rb
# Docs: docs/HR.md
class Companies::AttendanceConfigsController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.attendance_configs.includes(:branch)
        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        render json: { attendance_configs: @results.map { |c| format_config(c) }, pagination: @pagy.data_hash }
      end
    end
  end

  def show
    config = current_company.attendance_configs.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { attendance_config: format_config(config) } }
    end
  end

  def new
    respond_to { |f| f.html { render html: "", layout: true } }
  end

  def edit
    config = current_company.attendance_configs.find(params[:id])
    respond_to { |f| f.html { render html: "", layout: true } }
  end

  def create
    config = current_company.attendance_configs.new(config_params)
    if config.save
      redirect_to company_attendance_config_path(current_company, config), notice: "Attendance config created"
    else
      redirect_to new_company_attendance_config_path(current_company), alert: config.errors.full_messages.to_sentence
    end
  end

  def update
    config = current_company.attendance_configs.find(params[:id])
    if config.update(config_params)
      redirect_to company_attendance_config_path(current_company, config), notice: "Updated"
    else
      redirect_to edit_company_attendance_config_path(current_company, config), alert: config.errors.full_messages.to_sentence
    end
  end

  private

  def config_params
    params.require(:attendance_config).permit(:branch_id, :latitude, :longitude, :allowed_radius_meters, :allowed_wifi_ssid, :require_photo, :resolution_strategy)
  end

  def format_config(config)
    config.as_json(only: %i[id branch_id latitude longitude allowed_radius_meters allowed_wifi_ssid require_photo resolution_strategy created_at]).merge(
      branch: config.branch.as_json(only: %i[id name])
    )
  end
end
