require 'rails_helper'

RSpec.describe "role_appointments/new", type: :view do
  before(:each) do
    assign(:role_appointment, RoleAppointment.new(
      role: nil,
      appoint_to: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new role_appointment form" do
    render

    assert_select "form[action=?][method=?]", role_appointments_path, "post" do

      assert_select "input[name=?]", "role_appointment[role_id]"

      assert_select "input[name=?]", "role_appointment[appoint_to_id]"

      assert_select "input[name=?]", "role_appointment[name]"

      assert_select "input[name=?]", "role_appointment[description]"

      assert_select "input[name=?]", "role_appointment[code]"

      assert_select "input[name=?]", "role_appointment[status]"

      assert_select "input[name=?]", "role_appointment[business_type]"
    end
  end
end
