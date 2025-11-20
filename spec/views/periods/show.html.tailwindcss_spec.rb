require 'rails_helper'

RSpec.describe "periods/show", type: :view do
  before(:each) do
    assign(:period, Period.create!(
      company: nil,
      name: "Name",
      description: "Description",
      code: "Code",
      duration: 2
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/Code/)
    expect(rendered).to match(/2/)
  end
end
