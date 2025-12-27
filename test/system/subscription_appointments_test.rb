require "application_system_test_case"

class SubscriptionAppointmentsTest < ApplicationSystemTestCase
  setup do
    @subscription_appointment = subscription_appointments(:one)
  end

  test "visiting the index" do
    visit subscription_appointments_url
    assert_selector "h1", text: "Subscription appointments"
  end

  test "should create subscription appointment" do
    visit subscription_appointments_url
    click_on "New subscription appointment"

    fill_in "Appoint by", with: @subscription_appointment.appoint_by_id
    fill_in "Appoint by type", with: @subscription_appointment.appoint_by_type
    fill_in "Appoint for", with: @subscription_appointment.appoint_for_id
    fill_in "Appoint for type", with: @subscription_appointment.appoint_for_type
    fill_in "Appoint from", with: @subscription_appointment.appoint_from_id
    fill_in "Appoint from type", with: @subscription_appointment.appoint_from_type
    fill_in "Appoint to", with: @subscription_appointment.appoint_to_id
    fill_in "Appoint to type", with: @subscription_appointment.appoint_to_type
    fill_in "Business type", with: @subscription_appointment.business_type
    fill_in "Code", with: @subscription_appointment.code
    fill_in "Description", with: @subscription_appointment.description
    fill_in "Discarded at", with: @subscription_appointment.discarded_at
    fill_in "Lifecycle status", with: @subscription_appointment.lifecycle_status
    fill_in "Name", with: @subscription_appointment.name
    fill_in "Subscription", with: @subscription_appointment.subscription_id
    fill_in "Workflow status", with: @subscription_appointment.workflow_status
    click_on "Create Subscription appointment"

    assert_text "Subscription appointment was successfully created"
    click_on "Back"
  end

  test "should update Subscription appointment" do
    visit subscription_appointment_url(@subscription_appointment)
    click_on "Edit this subscription appointment", match: :first

    fill_in "Appoint by", with: @subscription_appointment.appoint_by_id
    fill_in "Appoint by type", with: @subscription_appointment.appoint_by_type
    fill_in "Appoint for", with: @subscription_appointment.appoint_for_id
    fill_in "Appoint for type", with: @subscription_appointment.appoint_for_type
    fill_in "Appoint from", with: @subscription_appointment.appoint_from_id
    fill_in "Appoint from type", with: @subscription_appointment.appoint_from_type
    fill_in "Appoint to", with: @subscription_appointment.appoint_to_id
    fill_in "Appoint to type", with: @subscription_appointment.appoint_to_type
    fill_in "Business type", with: @subscription_appointment.business_type
    fill_in "Code", with: @subscription_appointment.code
    fill_in "Description", with: @subscription_appointment.description
    fill_in "Discarded at", with: @subscription_appointment.discarded_at.to_s
    fill_in "Lifecycle status", with: @subscription_appointment.lifecycle_status
    fill_in "Name", with: @subscription_appointment.name
    fill_in "Subscription", with: @subscription_appointment.subscription_id
    fill_in "Workflow status", with: @subscription_appointment.workflow_status
    click_on "Update Subscription appointment"

    assert_text "Subscription appointment was successfully updated"
    click_on "Back"
  end

  test "should destroy Subscription appointment" do
    visit subscription_appointment_url(@subscription_appointment)
    accept_confirm { click_on "Destroy this subscription appointment", match: :first }

    assert_text "Subscription appointment was successfully destroyed"
  end
end
