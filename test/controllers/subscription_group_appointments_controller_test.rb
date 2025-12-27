require "test_helper"

class SubscriptionGroupAppointmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subscription_group_appointment = subscription_group_appointments(:one)
  end

  test "should get index" do
    get subscription_group_appointments_url
    assert_response :success
  end

  test "should get new" do
    get new_subscription_group_appointment_url
    assert_response :success
  end

  test "should create subscription_group_appointment" do
    assert_difference("SubscriptionGroupAppointment.count") do
      post subscription_group_appointments_url, params: { subscription_group_appointment: { appoint_by_id: @subscription_group_appointment.appoint_by_id, appoint_by_type: @subscription_group_appointment.appoint_by_type, appoint_for_id: @subscription_group_appointment.appoint_for_id, appoint_for_type: @subscription_group_appointment.appoint_for_type, appoint_from_id: @subscription_group_appointment.appoint_from_id, appoint_from_type: @subscription_group_appointment.appoint_from_type, appoint_to_id: @subscription_group_appointment.appoint_to_id, appoint_to_type: @subscription_group_appointment.appoint_to_type, business_type: @subscription_group_appointment.business_type, code: @subscription_group_appointment.code, description: @subscription_group_appointment.description, discarded_at: @subscription_group_appointment.discarded_at, lifecycle_status: @subscription_group_appointment.lifecycle_status, name: @subscription_group_appointment.name, subscription_group_id: @subscription_group_appointment.subscription_group_id, workflow_status: @subscription_group_appointment.workflow_status } }
    end

    assert_redirected_to subscription_group_appointment_url(SubscriptionGroupAppointment.last)
  end

  test "should show subscription_group_appointment" do
    get subscription_group_appointment_url(@subscription_group_appointment)
    assert_response :success
  end

  test "should get edit" do
    get edit_subscription_group_appointment_url(@subscription_group_appointment)
    assert_response :success
  end

  test "should update subscription_group_appointment" do
    patch subscription_group_appointment_url(@subscription_group_appointment), params: { subscription_group_appointment: { appoint_by_id: @subscription_group_appointment.appoint_by_id, appoint_by_type: @subscription_group_appointment.appoint_by_type, appoint_for_id: @subscription_group_appointment.appoint_for_id, appoint_for_type: @subscription_group_appointment.appoint_for_type, appoint_from_id: @subscription_group_appointment.appoint_from_id, appoint_from_type: @subscription_group_appointment.appoint_from_type, appoint_to_id: @subscription_group_appointment.appoint_to_id, appoint_to_type: @subscription_group_appointment.appoint_to_type, business_type: @subscription_group_appointment.business_type, code: @subscription_group_appointment.code, description: @subscription_group_appointment.description, discarded_at: @subscription_group_appointment.discarded_at, lifecycle_status: @subscription_group_appointment.lifecycle_status, name: @subscription_group_appointment.name, subscription_group_id: @subscription_group_appointment.subscription_group_id, workflow_status: @subscription_group_appointment.workflow_status } }
    assert_redirected_to subscription_group_appointment_url(@subscription_group_appointment)
  end

  test "should destroy subscription_group_appointment" do
    assert_difference("SubscriptionGroupAppointment.count", -1) do
      delete subscription_group_appointment_url(@subscription_group_appointment)
    end

    assert_redirected_to subscription_group_appointments_url
  end
end
