require 'rails_helper'

RSpec.describe "event_appointments/edit", type: :view do
  let(:event_appointment) {
    EventAppointment.create!(
      event: nil,
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
    assign(:event_appointment, event_appointment)
  end

  it "renders the edit event_appointment form" do
    render

    assert_select "form[action=?][method=?]", event_appointment_path(event_appointment), "post" do

      assert_select "input[name=?]", "event_appointment[event_id]"

      assert_select "input[name=?]", "event_appointment[appoint_from_id]"

      assert_select "input[name=?]", "event_appointment[appoint_to_id]"

      assert_select "input[name=?]", "event_appointment[appoint_for_id]"

      assert_select "input[name=?]", "event_appointment[appoint_by_id]"

      assert_select "input[name=?]", "event_appointment[name]"

      assert_select "input[name=?]", "event_appointment[description]"

      assert_select "input[name=?]", "event_appointment[code]"

      assert_select "input[name=?]", "event_appointment[status]"

      assert_select "input[name=?]", "event_appointment[business_type]"
    end
  end
end
