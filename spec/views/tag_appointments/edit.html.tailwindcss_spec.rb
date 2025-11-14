require 'rails_helper'

RSpec.describe "tag_appointments/edit", type: :view do
  let(:tag_appointment) {
    TagAppointment.create!(
      tag: nil,
      appoint_to: nil,
      value: "MyString",
      description: "MyString"
    )
  }

  before(:each) do
    assign(:tag_appointment, tag_appointment)
  end

  it "renders the edit tag_appointment form" do
    render

    assert_select "form[action=?][method=?]", tag_appointment_path(tag_appointment), "post" do

      assert_select "input[name=?]", "tag_appointment[tag_id]"

      assert_select "input[name=?]", "tag_appointment[appoint_to_id]"

      assert_select "input[name=?]", "tag_appointment[value]"

      assert_select "input[name=?]", "tag_appointment[description]"
    end
  end
end
