require 'rails_helper'

RSpec.describe "employee_groups/new", type: :view do
  before(:each) do
    assign(:employee_group, EmployeeGroup.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new employee_group form" do
    render

    assert_select "form[action=?][method=?]", employee_groups_path, "post" do

      assert_select "input[name=?]", "employee_group[company_id]"

      assert_select "input[name=?]", "employee_group[name]"

      assert_select "input[name=?]", "employee_group[description]"

      assert_select "input[name=?]", "employee_group[code]"

      assert_select "input[name=?]", "employee_group[status]"

      assert_select "input[name=?]", "employee_group[business_type]"
    end
  end
end
