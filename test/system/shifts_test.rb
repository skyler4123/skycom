require "application_system_test_case"

class ShiftsTest < ApplicationSystemTestCase
  setup do
    @shift = shifts(:one)
  end

  test "visiting the index" do
    visit shifts_url
    assert_selector "h1", text: "Shifts"
  end

  test "should create shift" do
    visit shifts_url
    click_on "New shift"

    fill_in "Company group", with: @shift.company_id
    fill_in "Company", with: @shift.branch_id
    fill_in "Description", with: @shift.description
    fill_in "Name", with: @shift.name
    fill_in "Period", with: @shift.period_id
    click_on "Create Shift"

    assert_text "Shift was successfully created"
    click_on "Back"
  end

  test "should update Shift" do
    visit shift_url(@shift)
    click_on "Edit this shift", match: :first

    fill_in "Company group", with: @shift.company_id
    fill_in "Company", with: @shift.branch_id
    fill_in "Description", with: @shift.description
    fill_in "Name", with: @shift.name
    fill_in "Period", with: @shift.period_id
    click_on "Update Shift"

    assert_text "Shift was successfully updated"
    click_on "Back"
  end

  test "should destroy Shift" do
    visit shift_url(@shift)
    accept_confirm { click_on "Destroy this shift", match: :first }

    assert_text "Shift was successfully destroyed"
  end
end
