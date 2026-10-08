# frozen_string_literal: true

# Approve an AttendanceRequest and create its AttendanceDay in one transaction.
# The day row stays the source of truth — the request only authorizes creation.
# Returns { success:, attendance_day: } | { success: false, errors: [...] }.
class AttendanceRequests::ApproveService
  HALF_DAY_SECONDS = 4 * 3600

  def self.call(request:, approver:)
    new(request: request, approver: approver).call
  end

  def initialize(request:, approver:)
    @request = request
    @approver = approver
  end

  def call
    return failure("Request is not pending") unless @request.status_pending?
    return failure("Approver is required") if @approver.nil?
    unless @approver.can?(:update, @request)
      return failure("You are not authorized to update this record")
    end
    return failure("Attendance already recorded for this date") if day_exists?

    day = nil
    ActiveRecord::Base.transaction do
      day = create_day!
      @request.update!(status: :approved, decided_by: @approver, decided_at: Time.current)
    end

    { success: true, attendance_day: day }
  end

  private

  def day_exists?
    AttendanceDay.exists?(
      company_id: @request.company_id,
      employee_id: @request.employee_id,
      attendance_date: @request.attendance_date
    )
  end

  def create_day!
    check_in = @request.check_in
    check_out = @request.check_out
    worked = check_out.present? ? (check_out - check_in).to_i : 0
    status = if check_out.blank?
      :missing_checkout
    elsif worked < HALF_DAY_SECONDS
      :half_day
    else
      :present
    end

    AttendanceDay.create!(
      company_id: @request.company_id,
      branch_id: @request.branch_id,
      employee_id: @request.employee_id,
      attendance_date: @request.attendance_date,
      check_in: check_in,
      check_out: check_out,
      total_seconds_worked: worked,
      attendance_status: status,
      recorded_method: :request,
      notes: @request.reason,
      approved_by_type: "Employee",
      approved_by_id: @approver.id,
      approved_at: Time.current
    )
  end

  def failure(message)
    { success: false, errors: [ message ] }
  end
end
