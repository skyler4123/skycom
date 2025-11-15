require 'rails_helper'

RSpec.describe "role_appointments/index", type: :view do
  before(:each) do
    assign(:role_appointments, [
      RoleAppointment.create!(
        role: nil,
        appoint_to: nil,
        name: "Name",
        description: "Description",
        status: 2,
        kind: 3
      ),
      RoleAppointment.create!(
        role: nil,
        appoint_to: nil,
        name: "Name",
        description: "Description",
        status: 2,
        kind: 3
      )
    ])
  end

  it "renders a list of role_appointments" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
  end
end
