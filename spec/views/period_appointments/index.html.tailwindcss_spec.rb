require 'rails_helper'

RSpec.describe "period_appointments/index", type: :view do
  before(:each) do
    assign(:period_appointments, [
      PeriodAppointment.create!(
        period: nil,
        appoint_to: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        value: "Value"
      ),
      PeriodAppointment.create!(
        period: nil,
        appoint_to: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        value: "Value"
      )
    ])
  end

  it "renders a list of period_appointments" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Value".to_s), count: 2
  end
end
