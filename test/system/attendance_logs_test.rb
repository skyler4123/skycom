require "application_system_test_case"

class AttendanceLogsTest < ApplicationSystemTestCase
  setup do
    @attendance_log = attendance_logs(:one)
  end

  test "visiting the index" do
    visit attendance_logs_url
    assert_selector "h1", text: "Attendance logs"
  end

  test "should create attendance log" do
    visit attendance_logs_url
    click_on "New attendance log"

    fill_in "Company group", with: @attendance_log.company_group_id
    fill_in "Company", with: @attendance_log.company_id
    fill_in "Customer", with: @attendance_log.customer_id
    fill_in "Device info", with: @attendance_log.device_info
    fill_in "Id address", with: @attendance_log.id_address
    fill_in "Location", with: @attendance_log.location
    fill_in "Logable", with: @attendance_log.logable_id
    fill_in "Logable type", with: @attendance_log.logable_type
    fill_in "Notes", with: @attendance_log.notes
    fill_in "Period", with: @attendance_log.period_id
    click_on "Create Attendance log"

    assert_text "Attendance log was successfully created"
    click_on "Back"
  end

  test "should update Attendance log" do
    visit attendance_log_url(@attendance_log)
    click_on "Edit this attendance log", match: :first

    fill_in "Company group", with: @attendance_log.company_group_id
    fill_in "Company", with: @attendance_log.company_id
    fill_in "Customer", with: @attendance_log.customer_id
    fill_in "Device info", with: @attendance_log.device_info
    fill_in "Id address", with: @attendance_log.id_address
    fill_in "Location", with: @attendance_log.location
    fill_in "Logable", with: @attendance_log.logable_id
    fill_in "Logable type", with: @attendance_log.logable_type
    fill_in "Notes", with: @attendance_log.notes
    fill_in "Period", with: @attendance_log.period_id
    click_on "Update Attendance log"

    assert_text "Attendance log was successfully updated"
    click_on "Back"
  end

  test "should destroy Attendance log" do
    visit attendance_log_url(@attendance_log)
    accept_confirm { click_on "Destroy this attendance log", match: :first }

    assert_text "Attendance log was successfully destroyed"
  end
end
