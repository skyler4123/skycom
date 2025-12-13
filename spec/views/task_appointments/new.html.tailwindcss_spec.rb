require 'rails_helper'

RSpec.describe "task_appointments/new", type: :view do
  before(:each) do
    assign(:task_appointment, TaskAppointment.new(
      task: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      appoint_by: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new task_appointment form" do
    render

    assert_select "form[action=?][method=?]", task_appointments_path, "post" do
      assert_select "input[name=?]", "task_appointment[task_id]"

      assert_select "input[name=?]", "task_appointment[appoint_from_id]"

      assert_select "input[name=?]", "task_appointment[appoint_to_id]"

      assert_select "input[name=?]", "task_appointment[appoint_for_id]"

      assert_select "input[name=?]", "task_appointment[appoint_by_id]"

      assert_select "input[name=?]", "task_appointment[name]"

      assert_select "input[name=?]", "task_appointment[description]"

      assert_select "input[name=?]", "task_appointment[code]"

      assert_select "input[name=?]", "task_appointment[status]"

      assert_select "input[name=?]", "task_appointment[business_type]"
    end
  end
end
