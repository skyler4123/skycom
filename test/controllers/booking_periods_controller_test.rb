require "test_helper"

class BookingPeriodsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @booking_period = booking_periods(:one)
  end

  test "should get index" do
    get booking_periods_url
    assert_response :success
  end

  test "should get new" do
    get new_booking_period_url
    assert_response :success
  end

  test "should create booking_period" do
    assert_difference("BookingPeriod.count") do
      post booking_periods_url, params: { booking_period: { booking_resource_id: @booking_period.booking_resource_id, business_type: @booking_period.business_type, lifecycle_status: @booking_period.lifecycle_status, period_id: @booking_period.period_id, workflow_status: @booking_period.workflow_status } }
    end

    assert_redirected_to booking_period_url(BookingPeriod.last)
  end

  test "should show booking_period" do
    get booking_period_url(@booking_period)
    assert_response :success
  end

  test "should get edit" do
    get edit_booking_period_url(@booking_period)
    assert_response :success
  end

  test "should update booking_period" do
    patch booking_period_url(@booking_period), params: { booking_period: { booking_resource_id: @booking_period.booking_resource_id, business_type: @booking_period.business_type, lifecycle_status: @booking_period.lifecycle_status, period_id: @booking_period.period_id, workflow_status: @booking_period.workflow_status } }
    assert_redirected_to booking_period_url(@booking_period)
  end

  test "should destroy booking_period" do
    assert_difference("BookingPeriod.count", -1) do
      delete booking_period_url(@booking_period)
    end

    assert_redirected_to booking_periods_url
  end
end
