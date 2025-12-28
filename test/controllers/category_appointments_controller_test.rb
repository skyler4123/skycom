require "test_helper"

class CategoryAppointmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category_appointment = category_appointments(:one)
  end

  test "should get index" do
    get category_appointments_url
    assert_response :success
  end

  test "should get new" do
    get new_category_appointment_url
    assert_response :success
  end

  test "should create category_appointment" do
    assert_difference("CategoryAppointment.count") do
      post category_appointments_url, params: { category_appointment: { appoint_by_id: @category_appointment.appoint_by_id, appoint_by_type: @category_appointment.appoint_by_type, appoint_for_id: @category_appointment.appoint_for_id, appoint_for_type: @category_appointment.appoint_for_type, appoint_from_id: @category_appointment.appoint_from_id, appoint_from_type: @category_appointment.appoint_from_type, appoint_to_id: @category_appointment.appoint_to_id, appoint_to_type: @category_appointment.appoint_to_type, category_id: @category_appointment.category_id, code: @category_appointment.code, description: @category_appointment.description, name: @category_appointment.name } }
    end

    assert_redirected_to category_appointment_url(CategoryAppointment.last)
  end

  test "should show category_appointment" do
    get category_appointment_url(@category_appointment)
    assert_response :success
  end

  test "should get edit" do
    get edit_category_appointment_url(@category_appointment)
    assert_response :success
  end

  test "should update category_appointment" do
    patch category_appointment_url(@category_appointment), params: { category_appointment: { appoint_by_id: @category_appointment.appoint_by_id, appoint_by_type: @category_appointment.appoint_by_type, appoint_for_id: @category_appointment.appoint_for_id, appoint_for_type: @category_appointment.appoint_for_type, appoint_from_id: @category_appointment.appoint_from_id, appoint_from_type: @category_appointment.appoint_from_type, appoint_to_id: @category_appointment.appoint_to_id, appoint_to_type: @category_appointment.appoint_to_type, category_id: @category_appointment.category_id, code: @category_appointment.code, description: @category_appointment.description, name: @category_appointment.name } }
    assert_redirected_to category_appointment_url(@category_appointment)
  end

  test "should destroy category_appointment" do
    assert_difference("CategoryAppointment.count", -1) do
      delete category_appointment_url(@category_appointment)
    end

    assert_redirected_to category_appointments_url
  end
end
