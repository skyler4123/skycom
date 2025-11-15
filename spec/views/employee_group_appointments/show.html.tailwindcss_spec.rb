require 'rails_helper'

RSpec.describe "employee_group_appointments/show", type: :view do
  before(:each) do
    assign(:employee_group_appointment, EmployeeGroupAppointment.create!(
      employee_group: nil,
      appoint_to: nil,
      name: "Name",
      description: "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
  end
end
