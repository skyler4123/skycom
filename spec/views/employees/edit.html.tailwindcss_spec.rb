require 'rails_helper'

RSpec.describe "employees/edit", type: :view do
  let(:employee) {
    Employee.create!(
      user: nil,
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:employee, employee)
  end

  it "renders the edit employee form" do
    render

    assert_select "form[action=?][method=?]", employee_path(employee), "post" do

      assert_select "input[name=?]", "employee[user_id]"

      assert_select "input[name=?]", "employee[company_id]"

      assert_select "input[name=?]", "employee[name]"

      assert_select "input[name=?]", "employee[description]"

      assert_select "input[name=?]", "employee[code]"

      assert_select "input[name=?]", "employee[status]"

      assert_select "input[name=?]", "employee[business_type]"
    end
  end
end
