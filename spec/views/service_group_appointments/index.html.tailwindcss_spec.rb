require 'rails_helper'

RSpec.describe "service_group_appointments/index", type: :view do
  before(:each) do
    assign(:service_group_appointments, [
      ServiceGroupAppointment.create!(
        service_group: nil,
        appoint_to: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        status: 2,
        duration: 3,
        business_type: 4
      ),
      ServiceGroupAppointment.create!(
        service_group: nil,
        appoint_to: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        status: 2,
        duration: 3,
        business_type: 4
      )
    ])
  end

  it "renders a list of service_group_appointments" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
  end
end
