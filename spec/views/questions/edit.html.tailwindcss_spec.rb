require 'rails_helper'

RSpec.describe "questions/edit", type: :view do
  let(:question) {
    Question.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:question, question)
  end

  it "renders the edit question form" do
    render

    assert_select "form[action=?][method=?]", question_path(question), "post" do
      assert_select "input[name=?]", "question[company_id]"

      assert_select "input[name=?]", "question[name]"

      assert_select "input[name=?]", "question[description]"

      assert_select "input[name=?]", "question[code]"

      assert_select "input[name=?]", "question[status]"

      assert_select "input[name=?]", "question[business_type]"
    end
  end
end
