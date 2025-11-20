require 'rails_helper'

RSpec.describe "payment_methods/show", type: :view do
  before(:each) do
    assign(:payment_method, PaymentMethod.create!(
      name: "Name",
      description: "Description",
      code: "Code",
      currency: 2,
      status: 3,
      business_type: 4
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/Code/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
  end
end
