require 'rails_helper'

RSpec.describe "carts/new", type: :view do
  before(:each) do
    assign(:cart, Cart.new(
      company: nil,
      cart_group: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new cart form" do
    render

    assert_select "form[action=?][method=?]", carts_path, "post" do

      assert_select "input[name=?]", "cart[company_id]"

      assert_select "input[name=?]", "cart[cart_group_id]"

      assert_select "input[name=?]", "cart[name]"

      assert_select "input[name=?]", "cart[description]"

      assert_select "input[name=?]", "cart[code]"

      assert_select "input[name=?]", "cart[status]"

      assert_select "input[name=?]", "cart[business_type]"
    end
  end
end
