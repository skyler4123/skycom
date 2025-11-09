require 'rails_helper'

RSpec.describe "employee_groups/show", type: :view do
  before(:each) do
    assign(:employee_group, EmployeeGroup.create!(
      name: "Name",
      company: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(//)
  end
end
