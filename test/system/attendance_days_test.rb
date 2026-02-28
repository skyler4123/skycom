require "application_system_test_case"

class AttendanceDaysTest < ApplicationSystemTestCase
  setup do
    @attendance_day = attendance_days(:one)
  end

  test "visiting the index" do
    visit attendance_days_url
    assert_selector "h1", text: "Attendance days"
  end

  test "should create attendance day" do
    visit attendance_days_url
    click_on "New attendance day"

    fill_in "Approved at", with: @attendance_day.approved_at
    fill_in "Approved by", with: @attendance_day.approved_by_id
    fill_in "Attendance date", with: @attendance_day.attendance_date
    fill_in "Attendance status", with: @attendance_day.attendance_status
    fill_in "Break end", with: @attendance_day.break_end
    fill_in "Break start", with: @attendance_day.break_start
    fill_in "Check in", with: @attendance_day.check_in
    fill_in "Check out", with: @attendance_day.check_out
    fill_in "Company group", with: @attendance_day.company_id
    fill_in "Company", with: @attendance_day.branch_id
    fill_in "Device", with: @attendance_day.device_id
    fill_in "Edited at", with: @attendance_day.edited_at
    fill_in "Edited by", with: @attendance_day.edited_by_id
    fill_in "Employee", with: @attendance_day.employee_id
    fill_in "Ip address", with: @attendance_day.ip_address
    fill_in "Location lat", with: @attendance_day.location_lat
    fill_in "Location lng", with: @attendance_day.location_lng
    fill_in "Logable", with: @attendance_day.logable_id
    fill_in "Logable type", with: @attendance_day.logable_type
    fill_in "Notes", with: @attendance_day.notes
    fill_in "Period", with: @attendance_day.period_id
    fill_in "Recorded method", with: @attendance_day.recorded_method
    fill_in "Shift", with: @attendance_day.shift_id
    fill_in "Total seconds break", with: @attendance_day.total_seconds_break
    fill_in "Total seconds overtime", with: @attendance_day.total_seconds_overtime
    fill_in "Total seconds present", with: @attendance_day.total_seconds_present
    fill_in "Total seconds worked", with: @attendance_day.total_seconds_worked
    click_on "Create Attendance day"

    assert_text "Attendance day was successfully created"
    click_on "Back"
  end

  test "should update Attendance day" do
    visit attendance_day_url(@attendance_day)
    click_on "Edit this attendance day", match: :first

    fill_in "Approved at", with: @attendance_day.approved_at.to_s
    fill_in "Approved by", with: @attendance_day.approved_by_id
    fill_in "Attendance date", with: @attendance_day.attendance_date
    fill_in "Attendance status", with: @attendance_day.attendance_status
    fill_in "Break end", with: @attendance_day.break_end.to_s
    fill_in "Break start", with: @attendance_day.break_start.to_s
    fill_in "Check in", with: @attendance_day.check_in.to_s
    fill_in "Check out", with: @attendance_day.check_out.to_s
    fill_in "Company group", with: @attendance_day.company_id
    fill_in "Company", with: @attendance_day.branch_id
    fill_in "Device", with: @attendance_day.device_id
    fill_in "Edited at", with: @attendance_day.edited_at.to_s
    fill_in "Edited by", with: @attendance_day.edited_by_id
    fill_in "Employee", with: @attendance_day.employee_id
    fill_in "Ip address", with: @attendance_day.ip_address
    fill_in "Location lat", with: @attendance_day.location_lat
    fill_in "Location lng", with: @attendance_day.location_lng
    fill_in "Logable", with: @attendance_day.logable_id
    fill_in "Logable type", with: @attendance_day.logable_type
    fill_in "Notes", with: @attendance_day.notes
    fill_in "Period", with: @attendance_day.period_id
    fill_in "Recorded method", with: @attendance_day.recorded_method
    fill_in "Shift", with: @attendance_day.shift_id
    fill_in "Total seconds break", with: @attendance_day.total_seconds_break
    fill_in "Total seconds overtime", with: @attendance_day.total_seconds_overtime
    fill_in "Total seconds present", with: @attendance_day.total_seconds_present
    fill_in "Total seconds worked", with: @attendance_day.total_seconds_worked
    click_on "Update Attendance day"

    assert_text "Attendance day was successfully updated"
    click_on "Back"
  end

  test "should destroy Attendance day" do
    visit attendance_day_url(@attendance_day)
    accept_confirm { click_on "Destroy this attendance day", match: :first }

    assert_text "Attendance day was successfully destroyed"
  end
end
