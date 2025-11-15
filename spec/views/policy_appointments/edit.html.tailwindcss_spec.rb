require 'rails_helper'

RSpec.describe "policy_appointments/edit", type: :view do
  let(:policy_appointment) {
    PolicyAppointment.create!(
      policy: nil,
      appoint_to: nil,
      name: "MyString",
      description: "MyString",
      status: 1,
      kind: 1
    )
  }

  before(:each) do
    assign(:policy_appointment, policy_appointment)
  end

  it "renders the edit policy_appointment form" do
    render

    assert_select "form[action=?][method=?]", policy_appointment_path(policy_appointment), "post" do

      assert_select "input[name=?]", "policy_appointment[policy_id]"

      assert_select "input[name=?]", "policy_appointment[appoint_to_id]"

      assert_select "input[name=?]", "policy_appointment[name]"

      assert_select "input[name=?]", "policy_appointment[description]"

      assert_select "input[name=?]", "policy_appointment[status]"

      assert_select "input[name=?]", "policy_appointment[kind]"
    end
  end
end
