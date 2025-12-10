require 'rails_helper'

RSpec.describe "article_groups/edit", type: :view do
  let(:article_group) {
    ArticleGroup.create!(
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
    assign(:article_group, article_group)
  end

  it "renders the edit article_group form" do
    render

    assert_select "form[action=?][method=?]", article_group_path(article_group), "post" do

      assert_select "input[name=?]", "article_group[company_group_id]"

      assert_select "input[name=?]", "article_group[company_id]"

      assert_select "input[name=?]", "article_group[title]"

      assert_select "input[name=?]", "article_group[content]"

      assert_select "input[name=?]", "article_group[name]"

      assert_select "input[name=?]", "article_group[description]"

      assert_select "input[name=?]", "article_group[code]"

      assert_select "input[name=?]", "article_group[status]"

      assert_select "input[name=?]", "article_group[business_type]"
    end
  end
end
