require 'rails_helper'

RSpec.describe "employee_groups/show", type: :view do
  before(:each) do
    assign(:employee_group, EmployeeGroup.create!(
      company: nil,
      name: "Name",
      description: "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
  end
end
