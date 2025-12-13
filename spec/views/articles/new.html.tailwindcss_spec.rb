require 'rails_helper'

RSpec.describe "articles/new", type: :view do
  before(:each) do
    assign(:article, Article.new(
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
    ))
  end

  it "renders new article form" do
    render

    assert_select "form[action=?][method=?]", articles_path, "post" do
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
