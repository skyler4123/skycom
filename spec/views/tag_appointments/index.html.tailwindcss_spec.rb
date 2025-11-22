require 'rails_helper'

RSpec.describe "tag_appointments/index", type: :view do
  before(:each) do
    assign(:tag_appointments, [
      TagAppointment.create!(
        tag: nil,
        appoint_from: nil,
        appoint_to: nil,
        appoint_for: nil,
        appoint_by: nil,
        value: "Value",
        description: "Description"
      ),
      TagAppointment.create!(
        tag: nil,
        appoint_from: nil,
        appoint_to: nil,
        appoint_for: nil,
        appoint_by: nil,
        value: "Value",
        description: "Description"
      )
    ])
  end

  it "renders a list of tag_appointments" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Value".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
  end
end
