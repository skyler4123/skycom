require 'rails_helper'

RSpec.describe "inventories/new", type: :view do
  before(:each) do
    assign(:inventory, Inventory.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new inventory form" do
    render

    assert_select "form[action=?][method=?]", inventories_path, "post" do
      assert_select "input[name=?]", "inventory[company_id]"

      assert_select "input[name=?]", "inventory[name]"

      assert_select "input[name=?]", "inventory[description]"

      assert_select "input[name=?]", "inventory[code]"

      assert_select "input[name=?]", "inventory[status]"

      assert_select "input[name=?]", "inventory[business_type]"
    end
  end
end
