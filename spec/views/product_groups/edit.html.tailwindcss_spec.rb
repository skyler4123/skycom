require 'rails_helper'

RSpec.describe "product_groups/edit", type: :view do
  let(:product_group) {
    ProductGroup.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:product_group, product_group)
  end

  it "renders the edit product_group form" do
    render

    assert_select "form[action=?][method=?]", product_group_path(product_group), "post" do
      assert_select "input[name=?]", "product_group[company_id]"

      assert_select "input[name=?]", "product_group[name]"

      assert_select "input[name=?]", "product_group[description]"

      assert_select "input[name=?]", "product_group[code]"

      assert_select "input[name=?]", "product_group[status]"

      assert_select "input[name=?]", "product_group[business_type]"
    end
  end
end
