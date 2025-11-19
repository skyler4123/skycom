require 'rails_helper'

RSpec.describe "orders/edit", type: :view do
  let(:order) {
    Order.create!(
      company: nil,
      customer: nil,
      name: "MyString",
      description: "MyString",
      currency: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:order, order)
  end

  it "renders the edit order form" do
    render

    assert_select "form[action=?][method=?]", order_path(order), "post" do

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
