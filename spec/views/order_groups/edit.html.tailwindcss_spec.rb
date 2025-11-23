require 'rails_helper'

RSpec.describe "order_groups/edit", type: :view do
  let(:order_group) {
    OrderGroup.create!(
      company: nil,
      customer: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      currency: 1,
      duration: 1,
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:order_group, order_group)
  end

  it "renders the edit order_group form" do
    render

    assert_select "form[action=?][method=?]", order_group_path(order_group), "post" do

      assert_select "input[name=?]", "order_group[company_id]"

      assert_select "input[name=?]", "order_group[customer_id]"

      assert_select "input[name=?]", "order_group[name]"

      assert_select "input[name=?]", "order_group[description]"

      assert_select "input[name=?]", "order_group[code]"

      assert_select "input[name=?]", "order_group[currency]"

      assert_select "input[name=?]", "order_group[duration]"

      assert_select "input[name=?]", "order_group[status]"

      assert_select "input[name=?]", "order_group[business_type]"
    end
  end
end
