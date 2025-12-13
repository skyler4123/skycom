require 'rails_helper'

RSpec.describe "purchase_items/edit", type: :view do
  let(:purchase_item) {
    PurchaseItem.create!(
      purchase: nil,
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
    assign(:purchase_item, purchase_item)
  end

  it "renders the edit purchase_item form" do
    render

    assert_select "form[action=?][method=?]", purchase_item_path(purchase_item), "post" do
      assert_select "input[name=?]", "purchase_item[purchase_id]"

      assert_select "input[name=?]", "purchase_item[name]"

      assert_select "input[name=?]", "purchase_item[description]"

      assert_select "input[name=?]", "purchase_item[code]"

      assert_select "input[name=?]", "purchase_item[sku]"

      assert_select "input[name=?]", "purchase_item[barcode]"

      assert_select "input[name=?]", "purchase_item[upc]"

      assert_select "input[name=?]", "purchase_item[ean]"

      assert_select "input[name=?]", "purchase_item[manufacturer_code]"

      assert_select "input[name=?]", "purchase_item[serial_number]"

      assert_select "input[name=?]", "purchase_item[batch_number]"

      assert_select "input[name=?]", "purchase_item[status]"

      assert_select "input[name=?]", "purchase_item[business_type]"
    end
  end
end
