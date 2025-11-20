require 'rails_helper'

RSpec.describe "product_groups/new", type: :view do
  before(:each) do
    assign(:product_group, ProductGroup.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new product_group form" do
    render

    assert_select "form[action=?][method=?]", product_groups_path, "post" do

      assert_select "input[name=?]", "product_group[company_id]"

      assert_select "input[name=?]", "product_group[name]"

      assert_select "input[name=?]", "product_group[description]"

      assert_select "input[name=?]", "product_group[code]"

      assert_select "input[name=?]", "product_group[status]"

      assert_select "input[name=?]", "product_group[business_type]"
    end
  end
end
