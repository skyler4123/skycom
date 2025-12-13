require 'rails_helper'

RSpec.describe "answers/edit", type: :view do
  let(:answer) {
    Answer.create!(
      question: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:answer, answer)
  end

  it "renders the edit answer form" do
    render

    assert_select "form[action=?][method=?]", answer_path(answer), "post" do
      assert_select "input[name=?]", "answer[question_id]"

      assert_select "input[name=?]", "answer[name]"

      assert_select "input[name=?]", "answer[description]"

      assert_select "input[name=?]", "answer[code]"

      assert_select "input[name=?]", "answer[status]"

      assert_select "input[name=?]", "answer[business_type]"
    end
  end
end
