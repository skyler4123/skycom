require 'rails_helper'

RSpec.describe "invoices/show", type: :view do
  before(:each) do
    assign(:invoice, Invoice.create!(
      order: nil,
      name: "Name",
      description: "Description",
      currency: "Currency",
      number: "Number",
      total: "Total",
      status: 2,
      business_type: 3
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/Currency/)
    expect(rendered).to match(/Number/)
    expect(rendered).to match(/Total/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
  end
end
