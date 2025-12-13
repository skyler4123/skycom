require 'rails_helper'

RSpec.describe "notification_appointments/edit", type: :view do
  let(:notification_appointment) {
    NotificationAppointment.create!(
      notification: nil,
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
    assign(:notification_appointment, notification_appointment)
  end

  it "renders the edit notification_appointment form" do
    render

    assert_select "form[action=?][method=?]", notification_appointment_path(notification_appointment), "post" do
      assert_select "input[name=?]", "notification_appointment[notification_id]"

      assert_select "input[name=?]", "notification_appointment[appoint_from_id]"

      assert_select "input[name=?]", "notification_appointment[appoint_to_id]"

      assert_select "input[name=?]", "notification_appointment[appoint_for_id]"

      assert_select "input[name=?]", "notification_appointment[appoint_by_id]"

      assert_select "input[name=?]", "notification_appointment[name]"

      assert_select "input[name=?]", "notification_appointment[description]"

      assert_select "input[name=?]", "notification_appointment[code]"

      assert_select "input[name=?]", "notification_appointment[status]"

      assert_select "input[name=?]", "notification_appointment[business_type]"
    end
  end
end
