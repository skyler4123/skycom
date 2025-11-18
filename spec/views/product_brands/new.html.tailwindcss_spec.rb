require 'rails_helper'

RSpec.describe "product_brands/new", type: :view do
  before(:each) do
    assign(:product_brand, ProductBrand.new(
      name: "MyString",
      description: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new product_brand form" do
    render

    assert_select "form[action=?][method=?]", product_brands_path, "post" do

      assert_select "input[name=?]", "product_brand[name]"

      assert_select "input[name=?]", "product_brand[description]"

      assert_select "input[name=?]", "product_brand[status]"

      assert_select "input[name=?]", "product_brand[business_type]"
    end
  end
end
