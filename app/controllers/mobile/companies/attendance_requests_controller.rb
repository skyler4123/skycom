class Mobile::Companies::AttendanceRequestsController < Mobile::Companies::BaseController
  def new
    @attendance_request = AttendanceRequest.new(
      attendance_date: Date.current,
      business_type: :onsite_miss,
      check_in: Time.zone.parse("#{Date.current} 09:00"),
      check_out: Time.zone.parse("#{Date.current} 17:30")
    )
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
      @attendance_request = attendance_request
      render :new, status: :unprocessable_content
    end
  end

  private

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
