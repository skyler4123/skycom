require 'rails_helper'

RSpec.describe "customer_group_appointments/new", type: :view do
  before(:each) do
    assign(:customer_group_appointment, CustomerGroupAppointment.new(
      customer_group: nil,
      appoint_to: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new customer_group_appointment form" do
    render

    assert_select "form[action=?][method=?]", customer_group_appointments_path, "post" do

      assert_select "input[name=?]", "customer_group_appointment[customer_group_id]"

      assert_select "input[name=?]", "customer_group_appointment[appoint_to_id]"

      assert_select "input[name=?]", "customer_group_appointment[name]"

      assert_select "input[name=?]", "customer_group_appointment[description]"

      assert_select "input[name=?]", "customer_group_appointment[code]"

      assert_select "input[name=?]", "customer_group_appointment[status]"

      assert_select "input[name=?]", "customer_group_appointment[business_type]"
    end
  end
end
