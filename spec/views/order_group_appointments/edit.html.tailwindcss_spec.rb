require 'rails_helper'

RSpec.describe "order_group_appointments/edit", type: :view do
  let(:order_group_appointment) {
    OrderGroupAppointment.create!(
      order_group: nil,
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
    )
  }

  before(:each) do
    assign(:order_group_appointment, order_group_appointment)
  end

  it "renders the edit order_group_appointment form" do
    render

    assert_select "form[action=?][method=?]", order_group_appointment_path(order_group_appointment), "post" do
      assert_select "input[name=?]", "order_group_appointment[order_group_id]"

      assert_select "input[name=?]", "order_group_appointment[appoint_from_id]"

      assert_select "input[name=?]", "order_group_appointment[appoint_to_id]"

      assert_select "input[name=?]", "order_group_appointment[appoint_for_id]"

      assert_select "input[name=?]", "order_group_appointment[appoint_by_id]"

      assert_select "input[name=?]", "order_group_appointment[unit_price]"

      assert_select "input[name=?]", "order_group_appointment[quantity]"

      assert_select "input[name=?]", "order_group_appointment[total_price]"

      assert_select "input[name=?]", "order_group_appointment[name]"

      assert_select "input[name=?]", "order_group_appointment[description]"

      assert_select "input[name=?]", "order_group_appointment[code]"

      assert_select "input[name=?]", "order_group_appointment[status]"

      assert_select "input[name=?]", "order_group_appointment[business_type]"
    end
  end
end
