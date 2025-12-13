require 'rails_helper'

RSpec.describe "cart_groups/new", type: :view do
  before(:each) do
    assign(:cart_group, CartGroup.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new cart_group form" do
    render

    assert_select "form[action=?][method=?]", cart_groups_path, "post" do
      assert_select "input[name=?]", "cart_group[company_id]"

      assert_select "input[name=?]", "cart_group[name]"

      assert_select "input[name=?]", "cart_group[description]"

      assert_select "input[name=?]", "cart_group[code]"

      assert_select "input[name=?]", "cart_group[status]"

      assert_select "input[name=?]", "cart_group[business_type]"
    end
  end
end
