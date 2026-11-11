# frozen_string_literal: true

# Mobile::Companies::AttendanceRequestsController — Shell-First new-request form.
# The form posts natively; a validation failure re-renders the same shell with
# data-errors and data-values so the JS form can show them and keep the input.
# Serves Stimulus: Mobile_Companies_AttendanceRequests_NewController
# Endpoints: GET /mobile/companies/:company_id/attendance_requests/new(.json),
#            POST /mobile/companies/:company_id/attendance_requests
# Docs: docs/MOBILE.md §2-§4
class Mobile::Companies::AttendanceRequestsController < Mobile::Companies::BaseController
  before_action :set_managers, only: %i[new create]

  def new
    @attendance_request = AttendanceRequest.new(
      attendance_date: Date.current,
      business_type: :onsite_miss,
      check_in: Time.zone.parse("#{Date.current} 09:00"),
      check_out: Time.zone.parse("#{Date.current} 17:30")
    )

    respond_to do |format|
      format.html do
        @page_title = "New Request"
        render_mobile_shell(json_url: form_json_url)
      end
      format.json { render json: form_payload }
    end
  end

  def create
    attendance_request = AttendanceRequest.new(request_params)
    attendance_request.company = @employee.company
    attendance_request.branch ||= @employee.branch
    attendance_request.employee = @employee
    attendance_request.status = :pending

    if attendance_request.save
      redirect_to new_mobile_company_attendance_request_path(@company), notice: "Attendance request submitted successfully"
    else
      render_request_errors(attendance_request)
    end
  end

  private

  def render_request_errors(attendance_request)
    respond_to do |format|
      format.html do
        @page_title = "New Request"
        render_mobile_shell(
          json_url: form_json_url,
          action: "new",
          status: :unprocessable_content,
          data: {
            errors: attendance_request.errors.full_messages.to_json,
            values: submitted_values.to_json
          }
        )
      end
      format.any { head :unprocessable_content }
    end
  end

  def form_json_url
    new_mobile_company_attendance_request_path(@company, format: :json)
  end

  def form_payload
    {
      employee: {
        name: @employee.name,
        branch_name: @employee.branch&.name,
        company_name: @company.name
      },
      company: { id: @company.id, name: @company.name },
      managers: @managers.map { |manager| { name: manager.name } },
      business_types: AttendanceRequest.business_types.keys,
      defaults: {
        attendance_date: @attendance_request.attendance_date&.iso8601,
        business_type: @attendance_request.business_type,
        check_in_time: @attendance_request.check_in&.strftime("%H:%M"),
        check_out_time: @attendance_request.check_out&.strftime("%H:%M")
      }
    }
  end

  def submitted_values
    params.require(:attendance_request)
      .permit(:attendance_date, :business_type, :check_in_time, :check_out_time, :reason)
      .to_h
  end

  def set_managers
    @managers = @employee.managers.to_a
    return if @managers.any?

    fallback = @company.employees.where.not(id: @employee.id).find_by(business_type: :owner) ||
               @company.employees.where.not(id: @employee.id).order(:created_at).first
    @managers = [ fallback ].compact
  end

  def request_params
    attrs = params.require(:attendance_request).permit(
      :attendance_date, :check_in_time, :check_out_time, :reason, :business_type
    ).to_h

    attendance_date = attrs["attendance_date"]
    attrs["check_in"] = combine_date_and_time(attendance_date, attrs.delete("check_in_time"))
    attrs["check_out"] = combine_date_and_time(attendance_date, attrs.delete("check_out_time"))
    attrs
  end

  def combine_date_and_time(date, time)
    return nil if date.blank? || time.blank?

    Time.zone.parse("#{date} #{time}")
  rescue ArgumentError
    nil
  end
end
