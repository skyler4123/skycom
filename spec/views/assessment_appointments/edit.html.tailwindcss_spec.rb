require 'rails_helper'

RSpec.describe "assessment_appointments/edit", type: :view do
  let(:assessment_appointment) {
    AssessmentAppointment.create!(
      assessment: nil,
      appoint_from: nil,
      appoint_to: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:assessment_appointment, assessment_appointment)
  end

  it "renders the edit assessment_appointment form" do
    render

    assert_select "form[action=?][method=?]", assessment_appointment_path(assessment_appointment), "post" do

      assert_select "input[name=?]", "assessment_appointment[assessment_id]"

      assert_select "input[name=?]", "assessment_appointment[appoint_from_id]"

      assert_select "input[name=?]", "assessment_appointment[appoint_to_id]"

      assert_select "input[name=?]", "assessment_appointment[name]"

      assert_select "input[name=?]", "assessment_appointment[description]"

      assert_select "input[name=?]", "assessment_appointment[code]"

      assert_select "input[name=?]", "assessment_appointment[status]"

      assert_select "input[name=?]", "assessment_appointment[business_type]"
    end
  end
end
