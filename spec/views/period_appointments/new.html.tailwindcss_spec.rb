require 'rails_helper'

RSpec.describe "period_appointments/new", type: :view do
  before(:each) do
    assign(:period_appointment, PeriodAppointment.new(
      period: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      appoint_by: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      value: "MyString"
    ))
  end

  it "renders new period_appointment form" do
    render

    assert_select "form[action=?][method=?]", period_appointments_path, "post" do

      assert_select "input[name=?]", "period_appointment[period_id]"

      assert_select "input[name=?]", "period_appointment[appoint_from_id]"

      assert_select "input[name=?]", "period_appointment[appoint_to_id]"

      assert_select "input[name=?]", "period_appointment[appoint_for_id]"

      assert_select "input[name=?]", "period_appointment[appoint_by_id]"

      assert_select "input[name=?]", "period_appointment[name]"

      assert_select "input[name=?]", "period_appointment[description]"

      assert_select "input[name=?]", "period_appointment[code]"

      assert_select "input[name=?]", "period_appointment[value]"
    end
  end
end
