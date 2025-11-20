require 'rails_helper'

RSpec.describe "period_appointments/show", type: :view do
  before(:each) do
    assign(:period_appointment, PeriodAppointment.create!(
      period: nil,
      appoint_to: nil,
      name: "Name",
      description: "Description",
      code: "Code",
      value: "Value"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/Code/)
    expect(rendered).to match(/Value/)
  end
end
