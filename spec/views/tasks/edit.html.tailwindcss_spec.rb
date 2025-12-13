require 'rails_helper'

RSpec.describe "tasks/edit", type: :view do
  let(:task) {
    Task.create!(
      company: nil,
      task_group: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      currency: 1,
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:task, task)
  end

  it "renders the edit task form" do
    render

    assert_select "form[action=?][method=?]", task_path(task), "post" do
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
