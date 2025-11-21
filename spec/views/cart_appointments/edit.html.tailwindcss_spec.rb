require 'rails_helper'

RSpec.describe "cart_appointments/edit", type: :view do
  let(:cart_appointment) {
    CartAppointment.create!(
      cart: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:cart_appointment, cart_appointment)
  end

  it "renders the edit cart_appointment form" do
    render

    assert_select "form[action=?][method=?]", cart_appointment_path(cart_appointment), "post" do

      assert_select "input[name=?]", "cart_appointment[cart_id]"

      assert_select "input[name=?]", "cart_appointment[appoint_from_id]"

      assert_select "input[name=?]", "cart_appointment[appoint_to_id]"

      assert_select "input[name=?]", "cart_appointment[appoint_for_id]"

      assert_select "input[name=?]", "cart_appointment[name]"

      assert_select "input[name=?]", "cart_appointment[description]"

      assert_select "input[name=?]", "cart_appointment[code]"

      assert_select "input[name=?]", "cart_appointment[status]"

      assert_select "input[name=?]", "cart_appointment[business_type]"
    end
  end
end
