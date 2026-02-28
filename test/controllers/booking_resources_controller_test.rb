require "test_helper"

class BookingResourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @booking_resource = booking_resources(:one)
  end

  test "should get index" do
    get booking_resources_url
    assert_response :success
  end

  test "should get new" do
    get new_booking_resource_url
    assert_response :success
  end

  test "should create booking_resource" do
    assert_difference("BookingResource.count") do
      post booking_resources_url, params: { booking_resource: { booking_resourceable_id: @booking_resource.booking_resourceable_id, booking_resourceable_type: @booking_resource.booking_resourceable_type, business_type: @booking_resource.business_type, company_id: @booking_resource.company_id, branch_id: @booking_resource.branch_id, description: @booking_resource.description, discarded_at: @booking_resource.discarded_at, lifecycle_status: @booking_resource.lifecycle_status, name: @booking_resource.name, workflow_status: @booking_resource.workflow_status } }
    end

    assert_redirected_to booking_resource_url(BookingResource.last)
  end

  test "should show booking_resource" do
    get booking_resource_url(@booking_resource)
    assert_response :success
  end

  test "should get edit" do
    get edit_booking_resource_url(@booking_resource)
    assert_response :success
  end

  test "should update booking_resource" do
    patch booking_resource_url(@booking_resource), params: { booking_resource: { booking_resourceable_id: @booking_resource.booking_resourceable_id, booking_resourceable_type: @booking_resource.booking_resourceable_type, business_type: @booking_resource.business_type, company_id: @booking_resource.company_id, branch_id: @booking_resource.branch_id, description: @booking_resource.description, discarded_at: @booking_resource.discarded_at, lifecycle_status: @booking_resource.lifecycle_status, name: @booking_resource.name, workflow_status: @booking_resource.workflow_status } }
    assert_redirected_to booking_resource_url(@booking_resource)
  end

  test "should destroy booking_resource" do
    assert_difference("BookingResource.count", -1) do
      delete booking_resource_url(@booking_resource)
    end

    assert_redirected_to booking_resources_url
  end
end
