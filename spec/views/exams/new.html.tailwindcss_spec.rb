require 'rails_helper'

RSpec.describe "exams/new", type: :view do
  before(:each) do
    assign(:exam, Exam.new(
      exam_group: nil,
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new exam form" do
    render

    assert_select "form[action=?][method=?]", exams_path, "post" do
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
