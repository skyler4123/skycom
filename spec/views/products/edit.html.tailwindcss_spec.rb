require 'rails_helper'

RSpec.describe "products/edit", type: :view do
  let(:product) {
    Product.create!(
      company: nil,
      product_brand: nil,
      name: "MyString",
      description: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:product, product)
  end

  it "renders the edit product form" do
    render

    assert_select "form[action=?][method=?]", product_path(product), "post" do

      assert_select "input[name=?]", "product[company_id]"

      assert_select "input[name=?]", "product[product_brand_id]"

      assert_select "input[name=?]", "product[name]"

      assert_select "input[name=?]", "product[description]"

      assert_select "input[name=?]", "product[status]"

      assert_select "input[name=?]", "product[business_type]"
    end
  end
end
