require 'rails_helper'

RSpec.describe "employees/edit", type: :view do
  let(:employee) {
    Employee.create!(
      name: "MyString",
      user: nil,
      company: nil
    )
  }

  before(:each) do
    assign(:employee, employee)
  end

  it "renders the edit employee form" do
    render

    assert_select "form[action=?][method=?]", employee_path(employee), "post" do

      assert_select "input[name=?]", "employee[name]"

      assert_select "input[name=?]", "employee[user_id]"

      assert_select "input[name=?]", "employee[company_id]"
    end
  end
end
