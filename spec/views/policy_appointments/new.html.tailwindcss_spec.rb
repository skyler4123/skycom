require 'rails_helper'

RSpec.describe "policy_appointments/new", type: :view do
  before(:each) do
    assign(:policy_appointment, PolicyAppointment.new(
      policy: nil,
      appoint_to: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new policy_appointment form" do
    render

    assert_select "form[action=?][method=?]", policy_appointments_path, "post" do

      assert_select "input[name=?]", "policy_appointment[policy_id]"

      assert_select "input[name=?]", "policy_appointment[appoint_to_id]"

      assert_select "input[name=?]", "policy_appointment[name]"

      assert_select "input[name=?]", "policy_appointment[description]"

      assert_select "input[name=?]", "policy_appointment[code]"

      assert_select "input[name=?]", "policy_appointment[status]"

      assert_select "input[name=?]", "policy_appointment[business_type]"
    end
  end
end
