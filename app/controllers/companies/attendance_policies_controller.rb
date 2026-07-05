class Companies::AttendancePoliciesController < Companies::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.attendance_policies.includes(:branch)
        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        render json: { attendance_policies: @results.map { |ap| format_ap(ap) }, pagination: @pagy.data_hash }
      end
    end
  end

  def show
    ap = current_company.attendance_policies.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { attendance_policy: format_ap(ap) } }
    end
  end

  def new
    respond_to { |f| f.html { render html: "", layout: true } }
  end

  def edit
    ap = current_company.attendance_policies.find(params[:id])
    respond_to { |f| f.html { render html: "", layout: true } }
  end

  def create
    ap = current_company.attendance_policies.new(ap_params)
    if ap.save
      redirect_to company_attendance_policy_path(current_company, ap), notice: "Attendance policy created"
    else
      redirect_to new_company_attendance_policy_path(current_company), alert: ap.errors.full_messages.to_sentence
    end
  end

  def update
    ap = current_company.attendance_policies.find(params[:id])
    if ap.update(ap_params)
      redirect_to company_attendance_policy_path(current_company, ap), notice: "Updated"
    else
      redirect_to edit_company_attendance_policy_path(current_company, ap), alert: ap.errors.full_messages.to_sentence
    end
  end

  private

  def ap_params
    params.require(:attendance_policy).permit(:branch_id, :latitude, :longitude, :allowed_radius_meters, :allowed_wifi_ssid, :require_photo, :resolution_strategy)
  end

  def format_ap(ap)
    ap.as_json(only: %i[id latitude longitude allowed_radius_meters allowed_wifi_ssid require_photo resolution_strategy created_at]).merge(
      branch: ap.branch.as_json(only: %i[id name])
    )
  end
end
