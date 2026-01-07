require "application_system_test_case"

class BookingResourcesTest < ApplicationSystemTestCase
  setup do
    @booking_resource = booking_resources(:one)
  end

  test "visiting the index" do
    visit booking_resources_url
    assert_selector "h1", text: "Booking resources"
  end

  test "should create booking resource" do
    visit booking_resources_url
    click_on "New booking resource"

    fill_in "Booking resourceable", with: @booking_resource.booking_resourceable_id
    fill_in "Booking resourceable type", with: @booking_resource.booking_resourceable_type
    fill_in "Business type", with: @booking_resource.business_type
    fill_in "Company group", with: @booking_resource.company_group_id
    fill_in "Company", with: @booking_resource.company_id
    fill_in "Description", with: @booking_resource.description
    fill_in "Discarded at", with: @booking_resource.discarded_at
    fill_in "Lifecycle status", with: @booking_resource.lifecycle_status
    fill_in "Name", with: @booking_resource.name
    fill_in "Workflow status", with: @booking_resource.workflow_status
    click_on "Create Booking resource"

    assert_text "Booking resource was successfully created"
    click_on "Back"
  end

  test "should update Booking resource" do
    visit booking_resource_url(@booking_resource)
    click_on "Edit this booking resource", match: :first

    fill_in "Booking resourceable", with: @booking_resource.booking_resourceable_id
    fill_in "Booking resourceable type", with: @booking_resource.booking_resourceable_type
    fill_in "Business type", with: @booking_resource.business_type
    fill_in "Company group", with: @booking_resource.company_group_id
    fill_in "Company", with: @booking_resource.company_id
    fill_in "Description", with: @booking_resource.description
    fill_in "Discarded at", with: @booking_resource.discarded_at.to_s
    fill_in "Lifecycle status", with: @booking_resource.lifecycle_status
    fill_in "Name", with: @booking_resource.name
    fill_in "Workflow status", with: @booking_resource.workflow_status
    click_on "Update Booking resource"

    assert_text "Booking resource was successfully updated"
    click_on "Back"
  end

  test "should destroy Booking resource" do
    visit booking_resource_url(@booking_resource)
    accept_confirm { click_on "Destroy this booking resource", match: :first }

    assert_text "Booking resource was successfully destroyed"
  end
end
