require 'rails_helper'

RSpec.describe "employee_groups/edit", type: :view do
  let(:employee_group) {
    EmployeeGroup.create!(
      company: nil,
      name: "MyString",
      description: "MyString"
    )
  }

  before(:each) do
    assign(:employee_group, employee_group)
  end

  it "renders the edit employee_group form" do
    render

    assert_select "form[action=?][method=?]", employee_group_path(employee_group), "post" do

      assert_select "input[name=?]", "employee_group[company_id]"

      assert_select "input[name=?]", "employee_group[name]"

      assert_select "input[name=?]", "employee_group[description]"
    end
  end
end
