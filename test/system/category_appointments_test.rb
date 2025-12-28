require "application_system_test_case"

class CategoryAppointmentsTest < ApplicationSystemTestCase
  setup do
    @category_appointment = category_appointments(:one)
  end

  test "visiting the index" do
    visit category_appointments_url
    assert_selector "h1", text: "Category appointments"
  end

  test "should create category appointment" do
    visit category_appointments_url
    click_on "New category appointment"

    fill_in "Appoint by", with: @category_appointment.appoint_by_id
    fill_in "Appoint by type", with: @category_appointment.appoint_by_type
    fill_in "Appoint for", with: @category_appointment.appoint_for_id
    fill_in "Appoint for type", with: @category_appointment.appoint_for_type
    fill_in "Appoint from", with: @category_appointment.appoint_from_id
    fill_in "Appoint from type", with: @category_appointment.appoint_from_type
    fill_in "Appoint to", with: @category_appointment.appoint_to_id
    fill_in "Appoint to type", with: @category_appointment.appoint_to_type
    fill_in "Category", with: @category_appointment.category_id
    fill_in "Code", with: @category_appointment.code
    fill_in "Description", with: @category_appointment.description
    fill_in "Name", with: @category_appointment.name
    click_on "Create Category appointment"

    assert_text "Category appointment was successfully created"
    click_on "Back"
  end

  test "should update Category appointment" do
    visit category_appointment_url(@category_appointment)
    click_on "Edit this category appointment", match: :first

    fill_in "Appoint by", with: @category_appointment.appoint_by_id
    fill_in "Appoint by type", with: @category_appointment.appoint_by_type
    fill_in "Appoint for", with: @category_appointment.appoint_for_id
    fill_in "Appoint for type", with: @category_appointment.appoint_for_type
    fill_in "Appoint from", with: @category_appointment.appoint_from_id
    fill_in "Appoint from type", with: @category_appointment.appoint_from_type
    fill_in "Appoint to", with: @category_appointment.appoint_to_id
    fill_in "Appoint to type", with: @category_appointment.appoint_to_type
    fill_in "Category", with: @category_appointment.category_id
    fill_in "Code", with: @category_appointment.code
    fill_in "Description", with: @category_appointment.description
    fill_in "Name", with: @category_appointment.name
    click_on "Update Category appointment"

    assert_text "Category appointment was successfully updated"
    click_on "Back"
  end

  test "should destroy Category appointment" do
    visit category_appointment_url(@category_appointment)
    accept_confirm { click_on "Destroy this category appointment", match: :first }

    assert_text "Category appointment was successfully destroyed"
  end
end
