require 'rails_helper'

RSpec.describe "carts/edit", type: :view do
  let(:cart) {
    Cart.create!(
      company: nil,
      cart_group: nil,
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
    )
  }

  before(:each) do
    assign(:cart, cart)
  end

  it "renders the edit cart form" do
    render

    assert_select "form[action=?][method=?]", cart_path(cart), "post" do
      assert_select "input[name=?]", "cart[company_id]"

      assert_select "input[name=?]", "cart[cart_group_id]"

      assert_select "input[name=?]", "cart[name]"

      assert_select "input[name=?]", "cart[description]"

      assert_select "input[name=?]", "cart[code]"

      assert_select "input[name=?]", "cart[sku]"

      assert_select "input[name=?]", "cart[barcode]"

      assert_select "input[name=?]", "cart[upc]"

      assert_select "input[name=?]", "cart[ean]"

      assert_select "input[name=?]", "cart[manufacturer_code]"

      assert_select "input[name=?]", "cart[serial_number]"

      assert_select "input[name=?]", "cart[batch_number]"

      assert_select "input[name=?]", "cart[status]"

      assert_select "input[name=?]", "cart[business_type]"
    end
  end
end
