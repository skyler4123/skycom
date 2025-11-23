require 'rails_helper'

RSpec.describe "payments/index", type: :view do
  before(:each) do
    assign(:payments, [
      Payment.create!(
        invoice: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        currency: 2,
        duration: 3,
        exchange_rate: "9.99",
        amount: "9.99",
        payment_method: "Payment Method",
        gateway_details: "Gateway Details",
        status: 4,
        business_type: 5
      ),
      Payment.create!(
        invoice: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        currency: 2,
        duration: 3,
        exchange_rate: "9.99",
        amount: "9.99",
        payment_method: "Payment Method",
        gateway_details: "Gateway Details",
        status: 4,
        business_type: 5
      )
    ])
  end

  it "renders a list of payments" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Payment Method".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Gateway Details".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(5.to_s), count: 2
  end
end
