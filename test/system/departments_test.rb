require "application_system_test_case"

class DepartmentsTest < ApplicationSystemTestCase
  setup do
    @department = departments(:one)
  end

  test "visiting the index" do
    visit departments_url
    assert_selector "h1", text: "Departments"
  end

  test "should create department" do
    visit departments_url
    click_on "New department"

    fill_in "Business type", with: @department.business_type
    fill_in "Code", with: @department.code
    fill_in "Company", with: @department.company_id
    fill_in "Description", with: @department.description
    fill_in "Discarded at", with: @department.discarded_at
    fill_in "Lifecycle status", with: @department.lifecycle_status
    fill_in "Name", with: @department.name
    fill_in "Workflow status", with: @department.workflow_status
    click_on "Create Department"

    assert_text "Department was successfully created"
    click_on "Back"
  end

  test "should update Department" do
    visit department_url(@department)
    click_on "Edit this department", match: :first

    fill_in "Business type", with: @department.business_type
    fill_in "Code", with: @department.code
    fill_in "Company", with: @department.company_id
    fill_in "Description", with: @department.description
    fill_in "Discarded at", with: @department.discarded_at.to_s
    fill_in "Lifecycle status", with: @department.lifecycle_status
    fill_in "Name", with: @department.name
    fill_in "Workflow status", with: @department.workflow_status
    click_on "Update Department"

    assert_text "Department was successfully updated"
    click_on "Back"
  end

  test "should destroy Department" do
    visit department_url(@department)
    accept_confirm { click_on "Destroy this department", match: :first }

    assert_text "Department was successfully destroyed"
  end
end
