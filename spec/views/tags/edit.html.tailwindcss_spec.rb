require 'rails_helper'

RSpec.describe "tags/edit", type: :view do
  let(:tag) {
    Tag.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString"
    )
  }

  before(:each) do
    assign(:tag, tag)
  end

  it "renders the edit tag form" do
    render

    assert_select "form[action=?][method=?]", tag_path(tag), "post" do
      assert_select "input[name=?]", "tag[company_id]"

      assert_select "input[name=?]", "tag[name]"

      assert_select "input[name=?]", "tag[description]"

      assert_select "input[name=?]", "tag[code]"
    end
  end
end
