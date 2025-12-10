require 'rails_helper'

RSpec.describe "document_groups/show", type: :view do
  before(:each) do
    assign(:document_group, DocumentGroup.create!(
      company_group: nil,
      company: nil,
      title: "Title",
      content: "",
      name: "Name",
      description: "Description",
      code: "Code",
      status: 2,
      business_type: 3
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Title/)
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/Code/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
  end
end
