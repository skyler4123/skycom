require 'rails_helper'

RSpec.describe "role_appointments/show", type: :view do
  before(:each) do
    assign(:role_appointment, RoleAppointment.create!(
      role: nil,
      appoint_to: nil,
      name: "Name",
      description: "Description",
      status: 2,
      kind: 3
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
  end
end
