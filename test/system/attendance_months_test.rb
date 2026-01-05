require "application_system_test_case"

class AttendanceMonthsTest < ApplicationSystemTestCase
  setup do
    @attendance_month = attendance_months(:one)
  end

  test "visiting the index" do
    visit attendance_months_url
    assert_selector "h1", text: "Attendance months"
  end

  test "should create attendance month" do
    visit attendance_months_url
    click_on "New attendance month"

    fill_in "Company group", with: @attendance_month.company_group_id
    fill_in "Company", with: @attendance_month.company_id
    fill_in "Customer", with: @attendance_month.customer_id
    fill_in "Logable", with: @attendance_month.logable_id
    fill_in "Logable type", with: @attendance_month.logable_type
    fill_in "Period", with: @attendance_month.period_id
    click_on "Create Attendance month"

    assert_text "Attendance month was successfully created"
    click_on "Back"
  end

  test "should update Attendance month" do
    visit attendance_month_url(@attendance_month)
    click_on "Edit this attendance month", match: :first

    fill_in "Company group", with: @attendance_month.company_group_id
    fill_in "Company", with: @attendance_month.company_id
    fill_in "Customer", with: @attendance_month.customer_id
    fill_in "Logable", with: @attendance_month.logable_id
    fill_in "Logable type", with: @attendance_month.logable_type
    fill_in "Period", with: @attendance_month.period_id
    click_on "Update Attendance month"

    assert_text "Attendance month was successfully updated"
    click_on "Back"
  end

  test "should destroy Attendance month" do
    visit attendance_month_url(@attendance_month)
    accept_confirm { click_on "Destroy this attendance month", match: :first }

    assert_text "Attendance month was successfully destroyed"
  end
end
