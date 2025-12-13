require 'rails_helper'

RSpec.describe "order_appointments/new", type: :view do
  before(:each) do
    assign(:order_appointment, OrderAppointment.new(
      order: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      appoint_by: nil,
      unit_price: "9.99",
      quantity: 1,
      total_price: "9.99",
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new order_appointment form" do
    render

    assert_select "form[action=?][method=?]", order_appointments_path, "post" do
      assert_select "input[name=?]", "order_appointment[order_id]"

      assert_select "input[name=?]", "order_appointment[appoint_from_id]"

      assert_select "input[name=?]", "order_appointment[appoint_to_id]"

      assert_select "input[name=?]", "order_appointment[appoint_for_id]"

      assert_select "input[name=?]", "order_appointment[appoint_by_id]"

      assert_select "input[name=?]", "order_appointment[unit_price]"

      assert_select "input[name=?]", "order_appointment[quantity]"

      assert_select "input[name=?]", "order_appointment[total_price]"

      assert_select "input[name=?]", "order_appointment[name]"

      assert_select "input[name=?]", "order_appointment[description]"

      assert_select "input[name=?]", "order_appointment[code]"

      assert_select "input[name=?]", "order_appointment[status]"

      assert_select "input[name=?]", "order_appointment[business_type]"
    end
  end
end
