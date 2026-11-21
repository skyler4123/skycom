# frozen_string_literal: true

# Mobile::Companies::AttendancesController — employee self check-in. The employee
# is resolved from the URL company + current_user; the submitted GPS fix is
# validated by Attendance::CheckInService against the branch geofence.
# Serves Stimulus: Mobile_Companies_Home_IndexController
# Endpoints: POST /mobile/companies/:company_id/attendances
# Docs: docs/MOBILE.md §4
class Mobile::Companies::AttendancesController < Mobile::Companies::BaseController
  def create
    branch = @employee.branch || @employee.company.branches.first
    location = check_in_location

    result = Attendance::CheckInService.new(
      employee: @employee,
      branch: branch,
      latitude: location[:latitude],
      longitude: location[:longitude],
      accuracy_meters: location[:accuracy],
      require_scheduled_shift: false,
      enforce_geofence: @employee.branch.present?
    ).call

    if result.success?
      redirect_to mobile_company_home_path(@company), notice: "Checked in successfully"
    else
      redirect_to mobile_company_home_path(@company), alert: result.error
    end
  end

  private

  def check_in_location
    @check_in_location ||= begin
      raw = params.permit(attendance: %i[latitude longitude accuracy])[:attendance] || {}
      {
        latitude: coordinate(raw[:latitude], -90..90),
        longitude: coordinate(raw[:longitude], -180..180),
        accuracy: coordinate(raw[:accuracy], 0..)
      }
    end
  end

  def coordinate(value, range)
    number = Float(value)
    number.finite? && range.cover?(number) ? number : nil
  rescue ArgumentError, TypeError
    nil
  end
end
