require 'rails_helper'

RSpec.describe "document_groups/new", type: :view do
  before(:each) do
    assign(:document_group, DocumentGroup.new(
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

  it "renders new document_group form" do
    render

    assert_select "form[action=?][method=?]", document_groups_path, "post" do
      assert_select "input[name=?]", "document_group[company_group_id]"

      assert_select "input[name=?]", "document_group[company_id]"

      assert_select "input[name=?]", "document_group[title]"

      assert_select "input[name=?]", "document_group[content]"

      assert_select "input[name=?]", "document_group[name]"

      assert_select "input[name=?]", "document_group[description]"

      assert_select "input[name=?]", "document_group[code]"

      assert_select "input[name=?]", "document_group[status]"

      assert_select "input[name=?]", "document_group[business_type]"
    end
  end
end
