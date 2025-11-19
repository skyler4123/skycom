require 'rails_helper'

RSpec.describe "order_item_appointments/new", type: :view do
  before(:each) do
    assign(:order_item_appointment, OrderItemAppointment.new(
      order: nil,
      appoint_to: nil,
      unit_price: "9.99",
      quantity: 1,
      total_price: "9.99",
      name: "MyString",
      description: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new order_item_appointment form" do
    render

    assert_select "form[action=?][method=?]", order_item_appointments_path, "post" do

      assert_select "input[name=?]", "order_item_appointment[order_id]"

      assert_select "input[name=?]", "order_item_appointment[appoint_to_id]"

      assert_select "input[name=?]", "order_item_appointment[unit_price]"

      assert_select "input[name=?]", "order_item_appointment[quantity]"

      assert_select "input[name=?]", "order_item_appointment[total_price]"

      assert_select "input[name=?]", "order_item_appointment[name]"

      assert_select "input[name=?]", "order_item_appointment[description]"

      assert_select "input[name=?]", "order_item_appointment[status]"

      assert_select "input[name=?]", "order_item_appointment[business_type]"
    end
  end
end
