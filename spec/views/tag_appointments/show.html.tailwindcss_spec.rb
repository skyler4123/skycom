require 'rails_helper'

RSpec.describe "tag_appointments/show", type: :view do
  before(:each) do
    assign(:tag_appointment, TagAppointment.create!(
      tag: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      appoint_by: nil,
      value: "Value",
      description: "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Value/)
    expect(rendered).to match(/Description/)
  end
end
