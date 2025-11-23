require 'rails_helper'

RSpec.describe "employee_appointments/edit", type: :view do
  let(:employee_appointment) {
    EmployeeAppointment.create!(
      employee: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      appoint_by: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString"
    )
  }

  before(:each) do
    assign(:employee_appointment, employee_appointment)
  end

  it "renders the edit employee_appointment form" do
    render

    assert_select "form[action=?][method=?]", employee_appointment_path(employee_appointment), "post" do

      assert_select "input[name=?]", "employee_appointment[employee_id]"

      assert_select "input[name=?]", "employee_appointment[appoint_from_id]"

      assert_select "input[name=?]", "employee_appointment[appoint_to_id]"

      assert_select "input[name=?]", "employee_appointment[appoint_for_id]"

      assert_select "input[name=?]", "employee_appointment[appoint_by_id]"

      assert_select "input[name=?]", "employee_appointment[name]"

      assert_select "input[name=?]", "employee_appointment[description]"

      assert_select "input[name=?]", "employee_appointment[code]"
    end
  end
end
