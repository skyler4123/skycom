require 'rails_helper'

RSpec.describe "task_groups/edit", type: :view do
  let(:task_group) {
    TaskGroup.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:task_group, task_group)
  end

  it "renders the edit task_group form" do
    render

    assert_select "form[action=?][method=?]", task_group_path(task_group), "post" do
      assert_select "input[name=?]", "task_group[company_id]"

      assert_select "input[name=?]", "task_group[name]"

      assert_select "input[name=?]", "task_group[description]"

      assert_select "input[name=?]", "task_group[code]"

      assert_select "input[name=?]", "task_group[status]"

      assert_select "input[name=?]", "task_group[business_type]"
    end
  end
end
