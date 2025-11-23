require 'rails_helper'

RSpec.describe "payments/show", type: :view do
  before(:each) do
    assign(:payment, Payment.create!(
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
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/Code/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/Payment Method/)
    expect(rendered).to match(/Gateway Details/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(/5/)
  end
end
