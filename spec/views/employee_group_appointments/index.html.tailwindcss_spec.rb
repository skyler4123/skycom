require 'rails_helper'

RSpec.describe "employee_group_appointments/index", type: :view do
  before(:each) do
    assign(:employee_group_appointments, [
      EmployeeGroupAppointment.create!(
        employee_group: nil,
        appoint_to: nil,
        name: "Name",
        description: "Description"
      ),
      EmployeeGroupAppointment.create!(
        employee_group: nil,
        appoint_to: nil,
        name: "Name",
        description: "Description"
      )
    ])
  end

  it "renders a list of employee_group_appointments" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
  end
end
