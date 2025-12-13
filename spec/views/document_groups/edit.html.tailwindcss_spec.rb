require 'rails_helper'

RSpec.describe "document_groups/edit", type: :view do
  let(:document_group) {
    DocumentGroup.create!(
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
    assign(:document_group, document_group)
  end

  it "renders the edit document_group form" do
    render

    assert_select "form[action=?][method=?]", document_group_path(document_group), "post" do
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
