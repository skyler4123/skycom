require 'rails_helper'

RSpec.describe "event_group_appointments/edit", type: :view do
  let(:event_group_appointment) {
    EventGroupAppointment.create!(
      event_group: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      appoint_by: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:event_group_appointment, event_group_appointment)
  end

  it "renders the edit event_group_appointment form" do
    render

    assert_select "form[action=?][method=?]", event_group_appointment_path(event_group_appointment), "post" do

      assert_select "input[name=?]", "event_group_appointment[event_group_id]"

      assert_select "input[name=?]", "event_group_appointment[appoint_from_id]"

      assert_select "input[name=?]", "event_group_appointment[appoint_to_id]"

      assert_select "input[name=?]", "event_group_appointment[appoint_for_id]"

      assert_select "input[name=?]", "event_group_appointment[appoint_by_id]"

      assert_select "input[name=?]", "event_group_appointment[name]"

      assert_select "input[name=?]", "event_group_appointment[description]"

      assert_select "input[name=?]", "event_group_appointment[code]"

      assert_select "input[name=?]", "event_group_appointment[status]"

      assert_select "input[name=?]", "event_group_appointment[business_type]"
    end
  end
end
