require 'rails_helper'

RSpec.describe "order_appointments/index", type: :view do
  before(:each) do
    assign(:order_appointments, [
      OrderAppointment.create!(
        order: nil,
        appoint_from: nil,
        appoint_to: nil,
        appoint_for: nil,
        appoint_by: nil,
        unit_price: "9.99",
        quantity: 2,
        total_price: "9.99",
        name: "Name",
        description: "Description",
        code: "Code",
        status: 3,
        business_type: 4
      ),
      OrderAppointment.create!(
        order: nil,
        appoint_from: nil,
        appoint_to: nil,
        appoint_for: nil,
        appoint_by: nil,
        unit_price: "9.99",
        quantity: 2,
        total_price: "9.99",
        name: "Name",
        description: "Description",
        code: "Code",
        status: 3,
        business_type: 4
      )
    ])
  end

  it "renders a list of order_appointments" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
  end
end
