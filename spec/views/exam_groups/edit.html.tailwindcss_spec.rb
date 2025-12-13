require 'rails_helper'

RSpec.describe "exam_groups/edit", type: :view do
  let(:exam_group) {
    ExamGroup.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:exam_group, exam_group)
  end

  it "renders the edit exam_group form" do
    render

    assert_select "form[action=?][method=?]", exam_group_path(exam_group), "post" do
      assert_select "input[name=?]", "exam_group[company_id]"

      assert_select "input[name=?]", "exam_group[name]"

      assert_select "input[name=?]", "exam_group[description]"

      assert_select "input[name=?]", "exam_group[code]"

      assert_select "input[name=?]", "exam_group[status]"

      assert_select "input[name=?]", "exam_group[business_type]"
    end
  end
end
