require 'rails_helper'

RSpec.describe "orders/show", type: :view do
  before(:each) do
    assign(:order, Order.create!(
      company: nil,
      customer: nil,
      name: "Name",
      description: "Description",
      code: "Code",
      sku: "Sku",
      barcode: "Barcode",
      upc: "Upc",
      ean: "Ean",
      manufacturer_code: "Manufacturer Code",
      serial_number: "Serial Number",
      batch_number: "Batch Number",
      currency: 2,
      duration: 3,
      status: 4,
      business_type: 5
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/Code/)
    expect(rendered).to match(/Sku/)
    expect(rendered).to match(/Barcode/)
    expect(rendered).to match(/Upc/)
    expect(rendered).to match(/Ean/)
    expect(rendered).to match(/Manufacturer Code/)
    expect(rendered).to match(/Serial Number/)
    expect(rendered).to match(/Batch Number/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(/5/)
  end
end
