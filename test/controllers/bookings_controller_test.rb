require "test_helper"

class BookingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @booking = bookings(:one)
  end

  test "should get index" do
    get bookings_url
    assert_response :success
  end

  test "should get new" do
    get new_booking_url
    assert_response :success
  end

  test "should create booking" do
    assert_difference("Booking.count") do
      post bookings_url, params: { booking: { appoint_by_id: @booking.appoint_by_id, appoint_by_type: @booking.appoint_by_type, appoint_for_id: @booking.appoint_for_id, appoint_for_type: @booking.appoint_for_type, appoint_from_id: @booking.appoint_from_id, appoint_from_type: @booking.appoint_from_type, appoint_to_id: @booking.appoint_to_id, appoint_to_type: @booking.appoint_to_type, booking_resource_id: @booking.booking_resource_id, business_type: @booking.business_type, company_id: @booking.company_id, branch_id: @booking.branch_id, description: @booking.description, discarded_at: @booking.discarded_at, lifecycle_status: @booking.lifecycle_status, name: @booking.name, price_id: @booking.price_id, workflow_status: @booking.workflow_status } }
    end

    assert_redirected_to booking_url(Booking.last)
  end

  test "should show booking" do
    get booking_url(@booking)
    assert_response :success
  end

  test "should get edit" do
    get edit_booking_url(@booking)
    assert_response :success
  end

  test "should update booking" do
    patch booking_url(@booking), params: { booking: { appoint_by_id: @booking.appoint_by_id, appoint_by_type: @booking.appoint_by_type, appoint_for_id: @booking.appoint_for_id, appoint_for_type: @booking.appoint_for_type, appoint_from_id: @booking.appoint_from_id, appoint_from_type: @booking.appoint_from_type, appoint_to_id: @booking.appoint_to_id, appoint_to_type: @booking.appoint_to_type, booking_resource_id: @booking.booking_resource_id, business_type: @booking.business_type, company_id: @booking.company_id, branch_id: @booking.branch_id, description: @booking.description, discarded_at: @booking.discarded_at, lifecycle_status: @booking.lifecycle_status, name: @booking.name, price_id: @booking.price_id, workflow_status: @booking.workflow_status } }
    assert_redirected_to booking_url(@booking)
  end

  test "should destroy booking" do
    assert_difference("Booking.count", -1) do
      delete booking_url(@booking)
    end

    assert_redirected_to bookings_url
  end
end
