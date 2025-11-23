require 'rails_helper'

RSpec.describe "product_appointments/edit", type: :view do
  let(:product_appointment) {
    ProductAppointment.create!(
      product: nil,
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
    assign(:product_appointment, product_appointment)
  end

  it "renders the edit product_appointment form" do
    render

    assert_select "form[action=?][method=?]", product_appointment_path(product_appointment), "post" do

      assert_select "input[name=?]", "product_appointment[product_id]"

      assert_select "input[name=?]", "product_appointment[appoint_from_id]"

      assert_select "input[name=?]", "product_appointment[appoint_to_id]"

      assert_select "input[name=?]", "product_appointment[appoint_for_id]"

      assert_select "input[name=?]", "product_appointment[appoint_by_id]"

      assert_select "input[name=?]", "product_appointment[name]"

      assert_select "input[name=?]", "product_appointment[description]"

      assert_select "input[name=?]", "product_appointment[code]"

      assert_select "input[name=?]", "product_appointment[status]"

      assert_select "input[name=?]", "product_appointment[business_type]"
    end
  end
end
