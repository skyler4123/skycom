require 'rails_helper'

RSpec.describe "payment_methods/edit", type: :view do
  let(:payment_method) {
    PaymentMethod.create!(
      name: "MyString",
      description: "MyString",
      code: "MyString",
      currency: 1,
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:payment_method, payment_method)
  end

  it "renders the edit payment_method form" do
    render

    assert_select "form[action=?][method=?]", payment_method_path(payment_method), "post" do

      assert_select "input[name=?]", "payment_method[name]"

      assert_select "input[name=?]", "payment_method[description]"

      assert_select "input[name=?]", "payment_method[code]"

      assert_select "input[name=?]", "payment_method[currency]"

      assert_select "input[name=?]", "payment_method[status]"

      assert_select "input[name=?]", "payment_method[business_type]"
    end
  end
end
