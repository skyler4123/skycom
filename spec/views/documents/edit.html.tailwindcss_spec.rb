require 'rails_helper'

RSpec.describe "documents/edit", type: :view do
  let(:document) {
    Document.create!(
      document_group: nil,
      company_group: nil,
      company: nil,
      title: "MyString",
      content: "",
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:document, document)
  end

  it "renders the edit document form" do
    render

    assert_select "form[action=?][method=?]", document_path(document), "post" do

      assert_select "input[name=?]", "document[document_group_id]"

      assert_select "input[name=?]", "document[company_group_id]"

      assert_select "input[name=?]", "document[company_id]"

      assert_select "input[name=?]", "document[title]"

      assert_select "input[name=?]", "document[content]"

      assert_select "input[name=?]", "document[name]"

      assert_select "input[name=?]", "document[description]"

      assert_select "input[name=?]", "document[code]"

      assert_select "input[name=?]", "document[status]"

      assert_select "input[name=?]", "document[business_type]"
    end
  end
end
