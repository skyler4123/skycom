require 'rails_helper'

RSpec.describe "products/index", type: :view do
  before(:each) do
    assign(:products, [
      Product.create!(
        company: nil,
        product_brand: nil,
        name: "Name",
        description: "Description",
        status: 2,
        business_type: 3
      ),
      Product.create!(
        company: nil,
        product_brand: nil,
        name: "Name",
        description: "Description",
        status: 2,
        business_type: 3
      )
    ])
  end

  it "renders a list of products" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
  end
end
