require 'rails_helper'

RSpec.describe "project_appointments/new", type: :view do
  before(:each) do
    assign(:project_appointment, ProjectAppointment.new(
      project: nil,
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

  it "renders new project_appointment form" do
    render

    assert_select "form[action=?][method=?]", project_appointments_path, "post" do

      assert_select "input[name=?]", "project_appointment[project_id]"

      assert_select "input[name=?]", "project_appointment[appoint_from_id]"

      assert_select "input[name=?]", "project_appointment[appoint_to_id]"

      assert_select "input[name=?]", "project_appointment[appoint_for_id]"

      assert_select "input[name=?]", "project_appointment[appoint_by_id]"

      assert_select "input[name=?]", "project_appointment[name]"

      assert_select "input[name=?]", "project_appointment[description]"

      assert_select "input[name=?]", "project_appointment[code]"

      assert_select "input[name=?]", "project_appointment[status]"

      assert_select "input[name=?]", "project_appointment[business_type]"
    end
  end
end
