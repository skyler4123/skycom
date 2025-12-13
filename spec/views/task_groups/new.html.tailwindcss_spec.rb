require 'rails_helper'

RSpec.describe "task_groups/new", type: :view do
  before(:each) do
    assign(:task_group, TaskGroup.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new task_group form" do
    render

    assert_select "form[action=?][method=?]", task_groups_path, "post" do
      assert_select "input[name=?]", "task_group[company_id]"

      assert_select "input[name=?]", "task_group[name]"

      assert_select "input[name=?]", "task_group[description]"

      assert_select "input[name=?]", "task_group[code]"

      assert_select "input[name=?]", "task_group[status]"

      assert_select "input[name=?]", "task_group[business_type]"
    end
  end
end
