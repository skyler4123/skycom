require 'rails_helper'

RSpec.describe "product_group_appointments/edit", type: :view do
  let(:product_group_appointment) {
    ProductGroupAppointment.create!(
      product_group: nil,
      appoint_to: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:product_group_appointment, product_group_appointment)
  end

  it "renders the edit product_group_appointment form" do
    render

    assert_select "form[action=?][method=?]", product_group_appointment_path(product_group_appointment), "post" do

      assert_select "input[name=?]", "product_group_appointment[product_group_id]"

      assert_select "input[name=?]", "product_group_appointment[appoint_to_id]"

      assert_select "input[name=?]", "product_group_appointment[name]"

      assert_select "input[name=?]", "product_group_appointment[description]"

      assert_select "input[name=?]", "product_group_appointment[code]"

      assert_select "input[name=?]", "product_group_appointment[status]"

      assert_select "input[name=?]", "product_group_appointment[business_type]"
    end
  end
end
