require 'rails_helper'

RSpec.describe "service_group_appointments/edit", type: :view do
  let(:service_group_appointment) {
    ServiceGroupAppointment.create!(
      service_group: nil,
      appoint_to: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      duration: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:service_group_appointment, service_group_appointment)
  end

  it "renders the edit service_group_appointment form" do
    render

    assert_select "form[action=?][method=?]", service_group_appointment_path(service_group_appointment), "post" do

      assert_select "input[name=?]", "service_group_appointment[service_group_id]"

      assert_select "input[name=?]", "service_group_appointment[appoint_to_id]"

      assert_select "input[name=?]", "service_group_appointment[name]"

      assert_select "input[name=?]", "service_group_appointment[description]"

      assert_select "input[name=?]", "service_group_appointment[code]"

      assert_select "input[name=?]", "service_group_appointment[status]"

      assert_select "input[name=?]", "service_group_appointment[duration]"

      assert_select "input[name=?]", "service_group_appointment[business_type]"
    end
  end
end
