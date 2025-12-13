require 'rails_helper'

RSpec.describe "tags/new", type: :view do
  before(:each) do
    assign(:tag, Tag.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString"
    ))
  end

  it "renders new tag form" do
    render

    assert_select "form[action=?][method=?]", tags_path, "post" do
      assert_select "input[name=?]", "tag[company_id]"

      assert_select "input[name=?]", "tag[name]"

      assert_select "input[name=?]", "tag[description]"

      assert_select "input[name=?]", "tag[code]"
    end
  end
end
