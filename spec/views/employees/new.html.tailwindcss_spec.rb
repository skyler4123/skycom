require 'rails_helper'

RSpec.describe "employees/new", type: :view do
  before(:each) do
    assign(:employee, Employee.new(
      user: nil,
      company: nil,
      name: "MyString",
      description: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new employee form" do
    render

    assert_select "form[action=?][method=?]", employees_path, "post" do

      assert_select "input[name=?]", "employee[user_id]"

      assert_select "input[name=?]", "employee[company_id]"

      assert_select "input[name=?]", "employee[name]"

      assert_select "input[name=?]", "employee[description]"

      assert_select "input[name=?]", "employee[status]"

      assert_select "input[name=?]", "employee[business_type]"
    end
  end
end
