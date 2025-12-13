require 'rails_helper'

RSpec.describe "tasks/new", type: :view do
  before(:each) do
    assign(:task, Task.new(
      company: nil,
      task_group: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      currency: 1,
      status: 1,
      business_type: 1
    ))
  end

  it "renders new task form" do
    render

    assert_select "form[action=?][method=?]", tasks_path, "post" do
      assert_select "input[name=?]", "task[company_id]"

      assert_select "input[name=?]", "task[task_group_id]"

      assert_select "input[name=?]", "task[name]"

      assert_select "input[name=?]", "task[description]"

      assert_select "input[name=?]", "task[code]"

      assert_select "input[name=?]", "task[currency]"

      assert_select "input[name=?]", "task[status]"

      assert_select "input[name=?]", "task[business_type]"
    end
  end
end
