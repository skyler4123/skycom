require 'rails_helper'

RSpec.describe "exam_appointments/edit", type: :view do
  let(:exam_appointment) {
    ExamAppointment.create!(
      exam: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      appoint_by: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:exam_appointment, exam_appointment)
  end

  it "renders the edit exam_appointment form" do
    render

    assert_select "form[action=?][method=?]", exam_appointment_path(exam_appointment), "post" do
      assert_select "input[name=?]", "exam_appointment[exam_id]"

      assert_select "input[name=?]", "exam_appointment[appoint_from_id]"

      assert_select "input[name=?]", "exam_appointment[appoint_to_id]"

      assert_select "input[name=?]", "exam_appointment[appoint_for_id]"

      assert_select "input[name=?]", "exam_appointment[appoint_by_id]"

      assert_select "input[name=?]", "exam_appointment[name]"

      assert_select "input[name=?]", "exam_appointment[description]"

      assert_select "input[name=?]", "exam_appointment[code]"

      assert_select "input[name=?]", "exam_appointment[status]"

      assert_select "input[name=?]", "exam_appointment[business_type]"
    end
  end
end
