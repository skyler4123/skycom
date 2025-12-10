require 'rails_helper'

RSpec.describe "document_group_appointments/index", type: :view do
  before(:each) do
    assign(:document_group_appointments, [
      DocumentGroupAppointment.create!(
        document_group: nil,
        appoint_from: nil,
        appoint_to: nil,
        appoint_for: nil,
        appoint_by: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        status: 2,
        business_type: 3
      ),
      DocumentGroupAppointment.create!(
        document_group: nil,
        appoint_from: nil,
        appoint_to: nil,
        appoint_for: nil,
        appoint_by: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        status: 2,
        business_type: 3
      )
    ])
  end

  it "renders a list of document_group_appointments" do
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
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
  end
end
