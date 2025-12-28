require "test_helper"

class SubscriptionAppointmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subscription_appointment = subscription_appointments(:one)
  end

  test "should get index" do
    get subscription_appointments_url
    assert_response :success
  end

  test "should get new" do
    get new_subscription_appointment_url
    assert_response :success
  end

  test "should create subscription_appointment" do
    assert_difference("SubscriptionAppointment.count") do
      post subscription_appointments_url, params: { subscription_appointment: { appoint_by_id: @subscription_appointment.appoint_by_id, appoint_by_type: @subscription_appointment.appoint_by_type, appoint_for_id: @subscription_appointment.appoint_for_id, appoint_for_type: @subscription_appointment.appoint_for_type, appoint_from_id: @subscription_appointment.appoint_from_id, appoint_from_type: @subscription_appointment.appoint_from_type, appoint_to_id: @subscription_appointment.appoint_to_id, appoint_to_type: @subscription_appointment.appoint_to_type, business_type: @subscription_appointment.business_type, code: @subscription_appointment.code, description: @subscription_appointment.description, discarded_at: @subscription_appointment.discarded_at, lifecycle_status: @subscription_appointment.lifecycle_status, name: @subscription_appointment.name, subscription_id: @subscription_appointment.subscription_id, workflow_status: @subscription_appointment.workflow_status } }
    end

    assert_redirected_to subscription_appointment_url(SubscriptionAppointment.last)
  end

  test "should show subscription_appointment" do
    get subscription_appointment_url(@subscription_appointment)
    assert_response :success
  end

  test "should get edit" do
    get edit_subscription_appointment_url(@subscription_appointment)
    assert_response :success
  end

  test "should update subscription_appointment" do
    patch subscription_appointment_url(@subscription_appointment), params: { subscription_appointment: { appoint_by_id: @subscription_appointment.appoint_by_id, appoint_by_type: @subscription_appointment.appoint_by_type, appoint_for_id: @subscription_appointment.appoint_for_id, appoint_for_type: @subscription_appointment.appoint_for_type, appoint_from_id: @subscription_appointment.appoint_from_id, appoint_from_type: @subscription_appointment.appoint_from_type, appoint_to_id: @subscription_appointment.appoint_to_id, appoint_to_type: @subscription_appointment.appoint_to_type, business_type: @subscription_appointment.business_type, code: @subscription_appointment.code, description: @subscription_appointment.description, discarded_at: @subscription_appointment.discarded_at, lifecycle_status: @subscription_appointment.lifecycle_status, name: @subscription_appointment.name, subscription_id: @subscription_appointment.subscription_id, workflow_status: @subscription_appointment.workflow_status } }
    assert_redirected_to subscription_appointment_url(@subscription_appointment)
  end

  test "should destroy subscription_appointment" do
    assert_difference("SubscriptionAppointment.count", -1) do
      delete subscription_appointment_url(@subscription_appointment)
    end

    assert_redirected_to subscription_appointments_url
  end
end
