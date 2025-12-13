require 'rails_helper'

RSpec.describe "inventory_items/edit", type: :view do
  let(:inventory_item) {
    InventoryItem.create!(
      inventory: nil,
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
    assign(:inventory_item, inventory_item)
  end

  it "renders the edit inventory_item form" do
    render

    assert_select "form[action=?][method=?]", inventory_item_path(inventory_item), "post" do
      assert_select "input[name=?]", "inventory_item[inventory_id]"

      assert_select "input[name=?]", "inventory_item[name]"

      assert_select "input[name=?]", "inventory_item[description]"

      assert_select "input[name=?]", "inventory_item[code]"

      assert_select "input[name=?]", "inventory_item[sku]"

      assert_select "input[name=?]", "inventory_item[barcode]"

      assert_select "input[name=?]", "inventory_item[upc]"

      assert_select "input[name=?]", "inventory_item[ean]"

      assert_select "input[name=?]", "inventory_item[manufacturer_code]"

      assert_select "input[name=?]", "inventory_item[serial_number]"

      assert_select "input[name=?]", "inventory_item[batch_number]"

      assert_select "input[name=?]", "inventory_item[status]"

      assert_select "input[name=?]", "inventory_item[business_type]"
    end
  end
end
