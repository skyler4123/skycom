require "test_helper"

class AttendanceDaysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @attendance_day = attendance_days(:one)
  end

  test "should get index" do
    get attendance_days_url
    assert_response :success
  end

  test "should get new" do
    get new_attendance_day_url
    assert_response :success
  end

  test "should create attendance_day" do
    assert_difference("AttendanceDay.count") do
      post attendance_days_url, params: { attendance_day: { approved_at: @attendance_day.approved_at, approved_by_id: @attendance_day.approved_by_id, attendance_date: @attendance_day.attendance_date, attendance_status: @attendance_day.attendance_status, break_end: @attendance_day.break_end, break_start: @attendance_day.break_start, check_in: @attendance_day.check_in, check_out: @attendance_day.check_out, company_group_id: @attendance_day.company_group_id, company_id: @attendance_day.company_id, device_id: @attendance_day.device_id, edited_at: @attendance_day.edited_at, edited_by_id: @attendance_day.edited_by_id, employee_id: @attendance_day.employee_id, ip_address: @attendance_day.ip_address, location_lat: @attendance_day.location_lat, location_lng: @attendance_day.location_lng, logable_id: @attendance_day.logable_id, logable_type: @attendance_day.logable_type, notes: @attendance_day.notes, period_id: @attendance_day.period_id, recorded_method: @attendance_day.recorded_method, shift_id: @attendance_day.shift_id, total_seconds_break: @attendance_day.total_seconds_break, total_seconds_overtime: @attendance_day.total_seconds_overtime, total_seconds_present: @attendance_day.total_seconds_present, total_seconds_worked: @attendance_day.total_seconds_worked } }
    end

    assert_redirected_to attendance_day_url(AttendanceDay.last)
  end

  test "should show attendance_day" do
    get attendance_day_url(@attendance_day)
    assert_response :success
  end

  test "should get edit" do
    get edit_attendance_day_url(@attendance_day)
    assert_response :success
  end

  test "should update attendance_day" do
    patch attendance_day_url(@attendance_day), params: { attendance_day: { approved_at: @attendance_day.approved_at, approved_by_id: @attendance_day.approved_by_id, attendance_date: @attendance_day.attendance_date, attendance_status: @attendance_day.attendance_status, break_end: @attendance_day.break_end, break_start: @attendance_day.break_start, check_in: @attendance_day.check_in, check_out: @attendance_day.check_out, company_group_id: @attendance_day.company_group_id, company_id: @attendance_day.company_id, device_id: @attendance_day.device_id, edited_at: @attendance_day.edited_at, edited_by_id: @attendance_day.edited_by_id, employee_id: @attendance_day.employee_id, ip_address: @attendance_day.ip_address, location_lat: @attendance_day.location_lat, location_lng: @attendance_day.location_lng, logable_id: @attendance_day.logable_id, logable_type: @attendance_day.logable_type, notes: @attendance_day.notes, period_id: @attendance_day.period_id, recorded_method: @attendance_day.recorded_method, shift_id: @attendance_day.shift_id, total_seconds_break: @attendance_day.total_seconds_break, total_seconds_overtime: @attendance_day.total_seconds_overtime, total_seconds_present: @attendance_day.total_seconds_present, total_seconds_worked: @attendance_day.total_seconds_worked } }
    assert_redirected_to attendance_day_url(@attendance_day)
  end

  test "should destroy attendance_day" do
    assert_difference("AttendanceDay.count", -1) do
      delete attendance_day_url(@attendance_day)
    end

    assert_redirected_to attendance_days_url
  end
end
