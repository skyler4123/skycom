require 'rails_helper'

RSpec.describe "documents/index", type: :view do
  before(:each) do
    assign(:documents, [
      Document.create!(
        document_group: nil,
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
      Document.create!(
        document_group: nil,
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

  it "renders a list of documents" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
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
