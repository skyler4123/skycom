require 'rails_helper'

RSpec.describe "orders/new", type: :view do
  before(:each) do
    assign(:order, Order.new(
      company: nil,
      customer: nil,
      name: "MyString",
      description: "MyString",
      currency: "MyString",
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

      assert_select "input[name=?]", "order[currency]"

      assert_select "input[name=?]", "order[status]"

      assert_select "input[name=?]", "order[business_type]"
    end
  end
end
