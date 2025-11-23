require 'rails_helper'

RSpec.describe "employee_appointments/index", type: :view do
  before(:each) do
    assign(:employee_appointments, [
      EmployeeAppointment.create!(
        employee: nil,
        appoint_from: nil,
        appoint_to: nil,
        appoint_for: nil,
        appoint_by: nil,
        name: "Name",
        description: "Description",
        code: "Code"
      ),
      EmployeeAppointment.create!(
        employee: nil,
        appoint_from: nil,
        appoint_to: nil,
        appoint_for: nil,
        appoint_by: nil,
        name: "Name",
        description: "Description",
        code: "Code"
      )
    ])
  end

  it "renders a list of employee_appointments" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Code".to_s), count: 2
  end
end
