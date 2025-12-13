require 'rails_helper'

RSpec.describe "employee_group_appointments/new", type: :view do
  before(:each) do
    assign(:employee_group_appointment, EmployeeGroupAppointment.new(
      employee_group: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      appoint_by: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString"
    ))
  end

  it "renders new employee_group_appointment form" do
    render

    assert_select "form[action=?][method=?]", employee_group_appointments_path, "post" do
      assert_select "input[name=?]", "employee_group_appointment[employee_group_id]"

      assert_select "input[name=?]", "employee_group_appointment[appoint_from_id]"

      assert_select "input[name=?]", "employee_group_appointment[appoint_to_id]"

      assert_select "input[name=?]", "employee_group_appointment[appoint_for_id]"

      assert_select "input[name=?]", "employee_group_appointment[appoint_by_id]"

      assert_select "input[name=?]", "employee_group_appointment[name]"

      assert_select "input[name=?]", "employee_group_appointment[description]"

      assert_select "input[name=?]", "employee_group_appointment[code]"
    end
  end
end
