require 'rails_helper'

RSpec.describe "setting_appointments/new", type: :view do
  before(:each) do
    assign(:setting_appointment, SettingAppointment.new(
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
    ))
  end

  it "renders new setting_appointment form" do
    render

    assert_select "form[action=?][method=?]", setting_appointments_path, "post" do

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
