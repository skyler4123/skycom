require 'rails_helper'

RSpec.describe "customer_groups/edit", type: :view do
  let(:customer_group) {
    CustomerGroup.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:customer_group, customer_group)
  end

  it "renders the edit customer_group form" do
    render

    assert_select "form[action=?][method=?]", customer_group_path(customer_group), "post" do

      assert_select "input[name=?]", "customer_group[company_id]"

      assert_select "input[name=?]", "customer_group[name]"

      assert_select "input[name=?]", "customer_group[description]"

      assert_select "input[name=?]", "customer_group[code]"

      assert_select "input[name=?]", "customer_group[status]"

      assert_select "input[name=?]", "customer_group[business_type]"
    end
  end
end
