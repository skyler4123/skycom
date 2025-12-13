require 'rails_helper'

RSpec.describe "facility_appointments/edit", type: :view do
  let(:facility_appointment) {
    FacilityAppointment.create!(
      facility: nil,
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
    assign(:facility_appointment, facility_appointment)
  end

  it "renders the edit facility_appointment form" do
    render

    assert_select "form[action=?][method=?]", facility_appointment_path(facility_appointment), "post" do
      assert_select "input[name=?]", "facility_appointment[facility_id]"

      assert_select "input[name=?]", "facility_appointment[appoint_from_id]"

      assert_select "input[name=?]", "facility_appointment[appoint_to_id]"

      assert_select "input[name=?]", "facility_appointment[appoint_for_id]"

      assert_select "input[name=?]", "facility_appointment[appoint_by_id]"

      assert_select "input[name=?]", "facility_appointment[name]"

      assert_select "input[name=?]", "facility_appointment[description]"

      assert_select "input[name=?]", "facility_appointment[code]"

      assert_select "input[name=?]", "facility_appointment[status]"

      assert_select "input[name=?]", "facility_appointment[business_type]"
    end
  end
end
