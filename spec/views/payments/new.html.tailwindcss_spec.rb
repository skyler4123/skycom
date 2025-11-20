require 'rails_helper'

RSpec.describe "payments/new", type: :view do
  before(:each) do
    assign(:payment, Payment.new(
      invoice: nil,
      name: "MyString",
      description: "MyString",
      currency: "MyString",
      exchange_rate: "9.99",
      amount: "9.99",
      payment_method: "MyString",
      gateway_details: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new payment form" do
    render

    assert_select "form[action=?][method=?]", payments_path, "post" do

      assert_select "input[name=?]", "payment[invoice_id]"

      assert_select "input[name=?]", "payment[name]"

      assert_select "input[name=?]", "payment[description]"

      assert_select "input[name=?]", "payment[currency]"

      assert_select "input[name=?]", "payment[exchange_rate]"

      assert_select "input[name=?]", "payment[amount]"

      assert_select "input[name=?]", "payment[payment_method]"

      assert_select "input[name=?]", "payment[gateway_details]"

      assert_select "input[name=?]", "payment[status]"

      assert_select "input[name=?]", "payment[business_type]"
    end
  end
end
