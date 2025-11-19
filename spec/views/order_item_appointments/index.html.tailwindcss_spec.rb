require 'rails_helper'

RSpec.describe "order_item_appointments/index", type: :view do
  before(:each) do
    assign(:order_item_appointments, [
      OrderItemAppointment.create!(
        order: nil,
        appoint_to: nil,
        unit_price: "9.99",
        quantity: 2,
        total_price: "9.99",
        name: "Name",
        description: "Description",
        status: 3,
        business_type: 4
      ),
      OrderItemAppointment.create!(
        order: nil,
        appoint_to: nil,
        unit_price: "9.99",
        quantity: 2,
        total_price: "9.99",
        name: "Name",
        description: "Description",
        status: 3,
        business_type: 4
      )
    ])
  end

  it "renders a list of order_item_appointments" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
  end
end
