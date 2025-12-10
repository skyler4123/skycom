require 'rails_helper'

RSpec.describe "document_groups/index", type: :view do
  before(:each) do
    assign(:document_groups, [
      DocumentGroup.create!(
        company_group: nil,
        company: nil,
        title: "Title",
        content: "",
        name: "Name",
        description: "Description",
        code: "Code",
        status: 2,
        business_type: 3
      ),
      DocumentGroup.create!(
        company_group: nil,
        company: nil,
        title: "Title",
        content: "",
        name: "Name",
        description: "Description",
        code: "Code",
        status: 2,
        business_type: 3
      )
    ])
  end

  it "renders a list of document_groups" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Title".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
  end
end
