require 'rails_helper'

RSpec.describe "policies/show", type: :view do
  before(:each) do
    assign(:policy, Policy.create!(
      company: nil,
      name: "Name",
      description: "Description",
      resource: "Resource",
      action: "Action",
      status: 2,
      kind: 3
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/Resource/)
    expect(rendered).to match(/Action/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
  end
end
