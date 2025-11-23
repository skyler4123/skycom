require 'rails_helper'

RSpec.describe "orders/index", type: :view do
  before(:each) do
    assign(:orders, [
      Order.create!(
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
      ),
      Order.create!(
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
      )
    ])
  end

  it "renders a list of orders" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Sku".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Barcode".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Upc".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Ean".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Manufacturer Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Serial Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Batch Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(5.to_s), count: 2
  end
end
