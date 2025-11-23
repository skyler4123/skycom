require 'rails_helper'

RSpec.describe "orders/new", type: :view do
  before(:each) do
    assign(:order, Order.new(
      company: nil,
      customer: nil,
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
      currency: 1,
      duration: 1,
      status: 1,
      business_type: 1
    ))
  end

  it "renders new order form" do
    render

    assert_select "form[action=?][method=?]", orders_path, "post" do

      assert_select "input[name=?]", "order[company_id]"

      assert_select "input[name=?]", "order[customer_id]"

      assert_select "input[name=?]", "order[name]"

      assert_select "input[name=?]", "order[description]"

      assert_select "input[name=?]", "order[code]"

      assert_select "input[name=?]", "order[sku]"

      assert_select "input[name=?]", "order[barcode]"

      assert_select "input[name=?]", "order[upc]"

      assert_select "input[name=?]", "order[ean]"

      assert_select "input[name=?]", "order[manufacturer_code]"

      assert_select "input[name=?]", "order[serial_number]"

      assert_select "input[name=?]", "order[batch_number]"

      assert_select "input[name=?]", "order[currency]"

      assert_select "input[name=?]", "order[duration]"

      assert_select "input[name=?]", "order[status]"

      assert_select "input[name=?]", "order[business_type]"
    end
  end
end
