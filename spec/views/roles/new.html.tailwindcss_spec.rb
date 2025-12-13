require 'rails_helper'

RSpec.describe "roles/new", type: :view do
  before(:each) do
    assign(:role, Role.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new role form" do
    render

    assert_select "form[action=?][method=?]", roles_path, "post" do
      assert_select "input[name=?]", "role[company_id]"

      assert_select "input[name=?]", "role[name]"

      assert_select "input[name=?]", "role[description]"

      assert_select "input[name=?]", "role[code]"

      assert_select "input[name=?]", "role[status]"

      assert_select "input[name=?]", "role[business_type]"
    end
  end
end
