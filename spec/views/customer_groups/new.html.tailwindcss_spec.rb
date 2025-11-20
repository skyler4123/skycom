require 'rails_helper'

RSpec.describe "customer_groups/new", type: :view do
  before(:each) do
    assign(:customer_group, CustomerGroup.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new customer_group form" do
    render

    assert_select "form[action=?][method=?]", customer_groups_path, "post" do

      assert_select "input[name=?]", "customer_group[company_id]"

      assert_select "input[name=?]", "customer_group[name]"

      assert_select "input[name=?]", "customer_group[description]"

      assert_select "input[name=?]", "customer_group[code]"

      assert_select "input[name=?]", "customer_group[status]"

      assert_select "input[name=?]", "customer_group[business_type]"
    end
  end
end
