require 'rails_helper'

RSpec.describe "products/new", type: :view do
  before(:each) do
    assign(:product, Product.new(
      company: nil,
      product_brand: nil,
      name: "MyString",
      description: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new product form" do
    render

    assert_select "form[action=?][method=?]", products_path, "post" do

      assert_select "input[name=?]", "product[company_id]"

      assert_select "input[name=?]", "product[product_brand_id]"

      assert_select "input[name=?]", "product[name]"

      assert_select "input[name=?]", "product[description]"

      assert_select "input[name=?]", "product[status]"

      assert_select "input[name=?]", "product[business_type]"
    end
  end
end
