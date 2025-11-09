require 'rails_helper'

RSpec.describe "employee_groups/index", type: :view do
  before(:each) do
    assign(:employee_groups, [
      EmployeeGroup.create!(
        name: "Name",
        company: nil
      ),
      EmployeeGroup.create!(
        name: "Name",
        company: nil
      )
    ])
  end

  it "renders a list of employee_groups" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
