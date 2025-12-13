require 'rails_helper'

RSpec.describe "answers/new", type: :view do
  before(:each) do
    assign(:answer, Answer.new(
      question: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new answer form" do
    render

    assert_select "form[action=?][method=?]", answers_path, "post" do
      assert_select "input[name=?]", "answer[question_id]"

      assert_select "input[name=?]", "answer[name]"

      assert_select "input[name=?]", "answer[description]"

      assert_select "input[name=?]", "answer[code]"

      assert_select "input[name=?]", "answer[status]"

      assert_select "input[name=?]", "answer[business_type]"
    end
  end
end
