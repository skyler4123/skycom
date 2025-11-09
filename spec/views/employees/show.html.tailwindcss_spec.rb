require 'rails_helper'

RSpec.describe "employees/show", type: :view do
  before(:each) do
    assign(:employee, Employee.create!(
      name: "Name",
      user: nil,
      company: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
