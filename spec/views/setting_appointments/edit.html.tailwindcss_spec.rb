require 'rails_helper'

RSpec.describe "setting_appointments/edit", type: :view do
  let(:setting_appointment) {
    SettingAppointment.create!(
      setting: nil,
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
    assign(:setting_appointment, setting_appointment)
  end

  it "renders the edit setting_appointment form" do
    render

    assert_select "form[action=?][method=?]", setting_appointment_path(setting_appointment), "post" do
      assert_select "input[name=?]", "setting_appointment[setting_id]"

      assert_select "input[name=?]", "setting_appointment[appoint_from_id]"

      assert_select "input[name=?]", "setting_appointment[appoint_to_id]"

      assert_select "input[name=?]", "setting_appointment[appoint_for_id]"

      assert_select "input[name=?]", "setting_appointment[appoint_by_id]"

      assert_select "input[name=?]", "setting_appointment[name]"

      assert_select "input[name=?]", "setting_appointment[description]"

      assert_select "input[name=?]", "setting_appointment[code]"

      assert_select "input[name=?]", "setting_appointment[status]"

      assert_select "input[name=?]", "setting_appointment[business_type]"
    end
  end
end
