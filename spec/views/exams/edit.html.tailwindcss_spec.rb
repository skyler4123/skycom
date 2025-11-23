require 'rails_helper'

RSpec.describe "exams/edit", type: :view do
  let(:exam) {
    Exam.create!(
      exam_group: nil,
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:exam, exam)
  end

  it "renders the edit exam form" do
    render

    assert_select "form[action=?][method=?]", exam_path(exam), "post" do

      assert_select "input[name=?]", "exam[exam_group_id]"

      assert_select "input[name=?]", "exam[company_id]"

      assert_select "input[name=?]", "exam[name]"

      assert_select "input[name=?]", "exam[description]"

      assert_select "input[name=?]", "exam[code]"

      assert_select "input[name=?]", "exam[status]"

      assert_select "input[name=?]", "exam[business_type]"
    end
  end
end
