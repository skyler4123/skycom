require "application_system_test_case"

class SubscriptionGroupAppointmentsTest < ApplicationSystemTestCase
  setup do
    @subscription_group_appointment = subscription_group_appointments(:one)
  end

  test "visiting the index" do
    visit subscription_group_appointments_url
    assert_selector "h1", text: "Subscription group appointments"
  end

  test "should create subscription group appointment" do
    visit subscription_group_appointments_url
    click_on "New subscription group appointment"

    fill_in "Appoint by", with: @subscription_group_appointment.appoint_by_id
    fill_in "Appoint by type", with: @subscription_group_appointment.appoint_by_type
    fill_in "Appoint for", with: @subscription_group_appointment.appoint_for_id
    fill_in "Appoint for type", with: @subscription_group_appointment.appoint_for_type
    fill_in "Appoint from", with: @subscription_group_appointment.appoint_from_id
    fill_in "Appoint from type", with: @subscription_group_appointment.appoint_from_type
    fill_in "Appoint to", with: @subscription_group_appointment.appoint_to_id
    fill_in "Appoint to type", with: @subscription_group_appointment.appoint_to_type
    fill_in "Business type", with: @subscription_group_appointment.business_type
    fill_in "Code", with: @subscription_group_appointment.code
    fill_in "Description", with: @subscription_group_appointment.description
    fill_in "Discarded at", with: @subscription_group_appointment.discarded_at
    fill_in "Lifecycle status", with: @subscription_group_appointment.lifecycle_status
    fill_in "Name", with: @subscription_group_appointment.name
    fill_in "Subscription group", with: @subscription_group_appointment.subscription_group_id
    fill_in "Workflow status", with: @subscription_group_appointment.workflow_status
    click_on "Create Subscription group appointment"

    assert_text "Subscription group appointment was successfully created"
    click_on "Back"
  end

  test "should update Subscription group appointment" do
    visit subscription_group_appointment_url(@subscription_group_appointment)
    click_on "Edit this subscription group appointment", match: :first

    fill_in "Appoint by", with: @subscription_group_appointment.appoint_by_id
    fill_in "Appoint by type", with: @subscription_group_appointment.appoint_by_type
    fill_in "Appoint for", with: @subscription_group_appointment.appoint_for_id
    fill_in "Appoint for type", with: @subscription_group_appointment.appoint_for_type
    fill_in "Appoint from", with: @subscription_group_appointment.appoint_from_id
    fill_in "Appoint from type", with: @subscription_group_appointment.appoint_from_type
    fill_in "Appoint to", with: @subscription_group_appointment.appoint_to_id
    fill_in "Appoint to type", with: @subscription_group_appointment.appoint_to_type
    fill_in "Business type", with: @subscription_group_appointment.business_type
    fill_in "Code", with: @subscription_group_appointment.code
    fill_in "Description", with: @subscription_group_appointment.description
    fill_in "Discarded at", with: @subscription_group_appointment.discarded_at.to_s
    fill_in "Lifecycle status", with: @subscription_group_appointment.lifecycle_status
    fill_in "Name", with: @subscription_group_appointment.name
    fill_in "Subscription group", with: @subscription_group_appointment.subscription_group_id
    fill_in "Workflow status", with: @subscription_group_appointment.workflow_status
    click_on "Update Subscription group appointment"

    assert_text "Subscription group appointment was successfully updated"
    click_on "Back"
  end

  test "should destroy Subscription group appointment" do
    visit subscription_group_appointment_url(@subscription_group_appointment)
    accept_confirm { click_on "Destroy this subscription group appointment", match: :first }

    assert_text "Subscription group appointment was successfully destroyed"
  end
end
