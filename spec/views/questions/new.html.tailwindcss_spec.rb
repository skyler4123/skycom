require 'rails_helper'

RSpec.describe "questions/new", type: :view do
  before(:each) do
    assign(:question, Question.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new question form" do
    render

    assert_select "form[action=?][method=?]", questions_path, "post" do
      assert_select "input[name=?]", "question[company_id]"

      assert_select "input[name=?]", "question[name]"

      assert_select "input[name=?]", "question[description]"

      assert_select "input[name=?]", "question[code]"

      assert_select "input[name=?]", "question[status]"

      assert_select "input[name=?]", "question[business_type]"
    end
  end
end
