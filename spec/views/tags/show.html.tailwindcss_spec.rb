require 'rails_helper'

RSpec.describe "tags/show", type: :view do
  before(:each) do
    assign(:tag, Tag.create!(
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
