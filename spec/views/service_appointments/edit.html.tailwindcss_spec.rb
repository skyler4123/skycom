require 'rails_helper'

RSpec.describe "service_appointments/edit", type: :view do
  let(:service_appointment) {
    ServiceAppointment.create!(
      service: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      appoint_by: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      duration: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:service_appointment, service_appointment)
  end

  it "renders the edit service_appointment form" do
    render

    assert_select "form[action=?][method=?]", service_appointment_path(service_appointment), "post" do

      assert_select "input[name=?]", "service_appointment[service_id]"

      assert_select "input[name=?]", "service_appointment[appoint_from_id]"

      assert_select "input[name=?]", "service_appointment[appoint_to_id]"

      assert_select "input[name=?]", "service_appointment[appoint_for_id]"

      assert_select "input[name=?]", "service_appointment[appoint_by_id]"

      assert_select "input[name=?]", "service_appointment[name]"

      assert_select "input[name=?]", "service_appointment[description]"

      assert_select "input[name=?]", "service_appointment[code]"

      assert_select "input[name=?]", "service_appointment[status]"

      assert_select "input[name=?]", "service_appointment[duration]"

      assert_select "input[name=?]", "service_appointment[business_type]"
    end
  end
end
