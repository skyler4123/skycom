require 'rails_helper'

RSpec.describe "articles/edit", type: :view do
  let(:article) {
    Article.create!(
      article_group: nil,
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
    assign(:article, article)
  end

  it "renders the edit article form" do
    render

    assert_select "form[action=?][method=?]", article_path(article), "post" do

      assert_select "input[name=?]", "article[article_group_id]"

      assert_select "input[name=?]", "article[company_group_id]"

      assert_select "input[name=?]", "article[company_id]"

      assert_select "input[name=?]", "article[title]"

      assert_select "input[name=?]", "article[content]"

      assert_select "input[name=?]", "article[name]"

      assert_select "input[name=?]", "article[description]"

      assert_select "input[name=?]", "article[code]"

      assert_select "input[name=?]", "article[status]"

      assert_select "input[name=?]", "article[business_type]"
    end
  end
end
