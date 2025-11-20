require 'rails_helper'

RSpec.describe "period_appointments/edit", type: :view do
  let(:period_appointment) {
    PeriodAppointment.create!(
      period: nil,
      appoint_to: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      value: "MyString"
    )
  }

  before(:each) do
    assign(:period_appointment, period_appointment)
  end

  it "renders the edit period_appointment form" do
    render

    assert_select "form[action=?][method=?]", period_appointment_path(period_appointment), "post" do

      assert_select "input[name=?]", "period_appointment[period_id]"

      assert_select "input[name=?]", "period_appointment[appoint_to_id]"

      assert_select "input[name=?]", "period_appointment[name]"

      assert_select "input[name=?]", "period_appointment[description]"

      assert_select "input[name=?]", "period_appointment[code]"

      assert_select "input[name=?]", "period_appointment[value]"
    end
  end
end
