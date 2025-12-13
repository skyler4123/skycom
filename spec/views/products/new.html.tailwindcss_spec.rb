require 'rails_helper'

RSpec.describe "products/new", type: :view do
  before(:each) do
    assign(:product, Product.new(
      company: nil,
      brand: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      sku: "MyString",
      barcode: "MyString",
      upc: "MyString",
      ean: "MyString",
      manufacturer_code: "MyString",
      serial_number: "MyString",
      batch_number: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new product form" do
    render

    assert_select "form[action=?][method=?]", products_path, "post" do
      assert_select "input[name=?]", "product[company_id]"

      assert_select "input[name=?]", "product[brand_id]"

      assert_select "input[name=?]", "product[name]"

      assert_select "input[name=?]", "product[description]"

      assert_select "input[name=?]", "product[code]"

      assert_select "input[name=?]", "product[sku]"

      assert_select "input[name=?]", "product[barcode]"

      assert_select "input[name=?]", "product[upc]"

      assert_select "input[name=?]", "product[ean]"

      assert_select "input[name=?]", "product[manufacturer_code]"

      assert_select "input[name=?]", "product[serial_number]"

      assert_select "input[name=?]", "product[batch_number]"

      assert_select "input[name=?]", "product[status]"

      assert_select "input[name=?]", "product[business_type]"
    end
  end
end
