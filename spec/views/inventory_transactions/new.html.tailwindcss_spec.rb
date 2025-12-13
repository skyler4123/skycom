require 'rails_helper'

RSpec.describe "inventory_transactions/new", type: :view do
  before(:each) do
    assign(:inventory_transaction, InventoryTransaction.new(
      company: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      appoint_by: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new inventory_transaction form" do
    render

    assert_select "form[action=?][method=?]", inventory_transactions_path, "post" do
      assert_select "input[name=?]", "inventory_transaction[company_id]"

      assert_select "input[name=?]", "inventory_transaction[appoint_from_id]"

      assert_select "input[name=?]", "inventory_transaction[appoint_to_id]"

      assert_select "input[name=?]", "inventory_transaction[appoint_for_id]"

      assert_select "input[name=?]", "inventory_transaction[appoint_by_id]"

      assert_select "input[name=?]", "inventory_transaction[name]"

      assert_select "input[name=?]", "inventory_transaction[description]"

      assert_select "input[name=?]", "inventory_transaction[code]"

      assert_select "input[name=?]", "inventory_transaction[status]"

      assert_select "input[name=?]", "inventory_transaction[business_type]"
    end
  end
end
