require 'rails_helper'

RSpec.describe "tag_appointments/new", type: :view do
  before(:each) do
    assign(:tag_appointment, TagAppointment.new(
      tag: nil,
      appoint_from: nil,
      appoint_to: nil,
      appoint_for: nil,
      appoint_by: nil,
      value: "MyString",
      description: "MyString"
    ))
  end

  it "renders new tag_appointment form" do
    render

    assert_select "form[action=?][method=?]", tag_appointments_path, "post" do
      assert_select "input[name=?]", "tag_appointment[tag_id]"

      assert_select "input[name=?]", "tag_appointment[appoint_from_id]"

      assert_select "input[name=?]", "tag_appointment[appoint_to_id]"

      assert_select "input[name=?]", "tag_appointment[appoint_for_id]"

      assert_select "input[name=?]", "tag_appointment[appoint_by_id]"

      assert_select "input[name=?]", "tag_appointment[value]"

      assert_select "input[name=?]", "tag_appointment[description]"
    end
  end
end
