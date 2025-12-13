require 'rails_helper'

RSpec.describe "inventories/edit", type: :view do
  let(:inventory) {
    Inventory.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:inventory, inventory)
  end

  it "renders the edit inventory form" do
    render

    assert_select "form[action=?][method=?]", inventory_path(inventory), "post" do
      assert_select "input[name=?]", "inventory[company_id]"

      assert_select "input[name=?]", "inventory[name]"

      assert_select "input[name=?]", "inventory[description]"

      assert_select "input[name=?]", "inventory[code]"

      assert_select "input[name=?]", "inventory[status]"

      assert_select "input[name=?]", "inventory[business_type]"
    end
  end
end
