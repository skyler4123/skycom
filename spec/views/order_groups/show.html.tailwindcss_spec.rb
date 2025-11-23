require 'rails_helper'

RSpec.describe "order_groups/show", type: :view do
  before(:each) do
    assign(:order_group, OrderGroup.create!(
      company: nil,
      customer: nil,
      name: "Name",
      description: "Description",
      code: "Code",
      currency: 2,
      duration: 3,
      status: 4,
      business_type: 5
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/Code/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(/5/)
  end
end
