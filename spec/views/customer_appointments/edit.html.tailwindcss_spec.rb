require 'rails_helper'

RSpec.describe "customer_appointments/edit", type: :view do
  let(:customer_appointment) {
    CustomerAppointment.create!(
      customer: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      appoint_by: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:customer_appointment, customer_appointment)
  end

  it "renders the edit customer_appointment form" do
    render

    assert_select "form[action=?][method=?]", customer_appointment_path(customer_appointment), "post" do
      assert_select "input[name=?]", "customer_appointment[customer_id]"

      assert_select "input[name=?]", "customer_appointment[appoint_from_id]"

      assert_select "input[name=?]", "customer_appointment[appoint_to_id]"

      assert_select "input[name=?]", "customer_appointment[appoint_for_id]"

      assert_select "input[name=?]", "customer_appointment[appoint_by_id]"

      assert_select "input[name=?]", "customer_appointment[name]"

      assert_select "input[name=?]", "customer_appointment[description]"

      assert_select "input[name=?]", "customer_appointment[code]"

      assert_select "input[name=?]", "customer_appointment[status]"

      assert_select "input[name=?]", "customer_appointment[business_type]"
    end
  end
end
