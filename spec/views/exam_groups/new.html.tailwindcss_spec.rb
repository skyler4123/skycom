require 'rails_helper'

RSpec.describe "exam_groups/new", type: :view do
  before(:each) do
    assign(:exam_group, ExamGroup.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new exam_group form" do
    render

    assert_select "form[action=?][method=?]", exam_groups_path, "post" do
      assert_select "input[name=?]", "exam_group[company_id]"

      assert_select "input[name=?]", "exam_group[name]"

      assert_select "input[name=?]", "exam_group[description]"

      assert_select "input[name=?]", "exam_group[code]"

      assert_select "input[name=?]", "exam_group[status]"

      assert_select "input[name=?]", "exam_group[business_type]"
    end
  end
end
