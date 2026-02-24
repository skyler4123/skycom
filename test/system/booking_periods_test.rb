require "application_system_test_case"

class BookingPeriodsTest < ApplicationSystemTestCase
  setup do
    @booking_period = booking_periods(:one)
  end

  test "visiting the index" do
    visit booking_periods_url
    assert_selector "h1", text: "Booking periods"
  end

  test "should create booking period" do
    visit booking_periods_url
    click_on "New booking period"

    fill_in "Booking resource", with: @booking_period.booking_resource_id
    fill_in "Business type", with: @booking_period.business_type
    fill_in "Lifecycle status", with: @booking_period.lifecycle_status
    fill_in "Period", with: @booking_period.period_id
    fill_in "Workflow status", with: @booking_period.workflow_status
    click_on "Create Booking period"

    assert_text "Booking period was successfully created"
    click_on "Back"
  end

  test "should update Booking period" do
    visit booking_period_url(@booking_period)
    click_on "Edit this booking period", match: :first

    fill_in "Booking resource", with: @booking_period.booking_resource_id
    fill_in "Business type", with: @booking_period.business_type
    fill_in "Lifecycle status", with: @booking_period.lifecycle_status
    fill_in "Period", with: @booking_period.period_id
    fill_in "Workflow status", with: @booking_period.workflow_status
    click_on "Update Booking period"

    assert_text "Booking period was successfully updated"
    click_on "Back"
  end

  test "should destroy Booking period" do
    visit booking_period_url(@booking_period)
    accept_confirm { click_on "Destroy this booking period", match: :first }

    assert_text "Booking period was successfully destroyed"
  end
end
