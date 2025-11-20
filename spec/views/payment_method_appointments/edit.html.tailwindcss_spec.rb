require 'rails_helper'

RSpec.describe "payment_method_appointments/edit", type: :view do
  let(:payment_method_appointment) {
    PaymentMethodAppointment.create!(
      payment_method: nil,
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:payment_method_appointment, payment_method_appointment)
  end

  it "renders the edit payment_method_appointment form" do
    render

    assert_select "form[action=?][method=?]", payment_method_appointment_path(payment_method_appointment), "post" do

      assert_select "input[name=?]", "payment_method_appointment[payment_method_id]"

      assert_select "input[name=?]", "payment_method_appointment[company_id]"

      assert_select "input[name=?]", "payment_method_appointment[name]"

      assert_select "input[name=?]", "payment_method_appointment[description]"

      assert_select "input[name=?]", "payment_method_appointment[code]"

      assert_select "input[name=?]", "payment_method_appointment[status]"

      assert_select "input[name=?]", "payment_method_appointment[business_type]"
    end
  end
end
