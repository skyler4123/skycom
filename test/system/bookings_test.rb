require "application_system_test_case"

class BookingsTest < ApplicationSystemTestCase
  setup do
    @booking = bookings(:one)
  end

  test "visiting the index" do
    visit bookings_url
    assert_selector "h1", text: "Bookings"
  end

  test "should create booking" do
    visit bookings_url
    click_on "New booking"

    fill_in "Appoint by", with: @booking.appoint_by_id
    fill_in "Appoint by type", with: @booking.appoint_by_type
    fill_in "Appoint for", with: @booking.appoint_for_id
    fill_in "Appoint for type", with: @booking.appoint_for_type
    fill_in "Appoint from", with: @booking.appoint_from_id
    fill_in "Appoint from type", with: @booking.appoint_from_type
    fill_in "Appoint to", with: @booking.appoint_to_id
    fill_in "Appoint to type", with: @booking.appoint_to_type
    fill_in "Booking resource", with: @booking.booking_resource_id
    fill_in "Business type", with: @booking.business_type
    fill_in "Company group", with: @booking.company_id
    fill_in "Company", with: @booking.branch_id
    fill_in "Description", with: @booking.description
    fill_in "Discarded at", with: @booking.discarded_at
    fill_in "Lifecycle status", with: @booking.lifecycle_status
    fill_in "Name", with: @booking.name
    fill_in "Price", with: @booking.price_id
    fill_in "Workflow status", with: @booking.workflow_status
    click_on "Create Booking"

    assert_text "Booking was successfully created"
    click_on "Back"
  end

  test "should update Booking" do
    visit booking_url(@booking)
    click_on "Edit this booking", match: :first

    fill_in "Appoint by", with: @booking.appoint_by_id
    fill_in "Appoint by type", with: @booking.appoint_by_type
    fill_in "Appoint for", with: @booking.appoint_for_id
    fill_in "Appoint for type", with: @booking.appoint_for_type
    fill_in "Appoint from", with: @booking.appoint_from_id
    fill_in "Appoint from type", with: @booking.appoint_from_type
    fill_in "Appoint to", with: @booking.appoint_to_id
    fill_in "Appoint to type", with: @booking.appoint_to_type
    fill_in "Booking resource", with: @booking.booking_resource_id
    fill_in "Business type", with: @booking.business_type
    fill_in "Company group", with: @booking.company_id
    fill_in "Company", with: @booking.branch_id
    fill_in "Description", with: @booking.description
    fill_in "Discarded at", with: @booking.discarded_at.to_s
    fill_in "Lifecycle status", with: @booking.lifecycle_status
    fill_in "Name", with: @booking.name
    fill_in "Price", with: @booking.price_id
    fill_in "Workflow status", with: @booking.workflow_status
    click_on "Update Booking"

    assert_text "Booking was successfully updated"
    click_on "Back"
  end

  test "should destroy Booking" do
    visit booking_url(@booking)
    accept_confirm { click_on "Destroy this booking", match: :first }

    assert_text "Booking was successfully destroyed"
  end
end
