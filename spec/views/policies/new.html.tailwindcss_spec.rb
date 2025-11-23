require 'rails_helper'

RSpec.describe "policies/new", type: :view do
  before(:each) do
    assign(:policy, Policy.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      resource: "MyString",
      action: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new policy form" do
    render

    assert_select "form[action=?][method=?]", policies_path, "post" do

      assert_select "input[name=?]", "policy[company_id]"

      assert_select "input[name=?]", "policy[name]"

      assert_select "input[name=?]", "policy[description]"

      assert_select "input[name=?]", "policy[code]"

      assert_select "input[name=?]", "policy[resource]"

      assert_select "input[name=?]", "policy[action]"

      assert_select "input[name=?]", "policy[status]"

      assert_select "input[name=?]", "policy[business_type]"
    end
  end
end
