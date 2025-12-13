require 'rails_helper'

RSpec.describe "documents/new", type: :view do
  before(:each) do
    assign(:document, Document.new(
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
    ))
  end

  it "renders new document form" do
    render

    assert_select "form[action=?][method=?]", documents_path, "post" do
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
