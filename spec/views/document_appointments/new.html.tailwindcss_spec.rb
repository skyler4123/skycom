require 'rails_helper'

RSpec.describe "document_appointments/new", type: :view do
  before(:each) do
    assign(:document_appointment, DocumentAppointment.new(
      document: nil,
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

  it "renders new document_appointment form" do
    render

    assert_select "form[action=?][method=?]", document_appointments_path, "post" do
      assert_select "input[name=?]", "document_appointment[document_id]"

      assert_select "input[name=?]", "document_appointment[appoint_from_id]"

      assert_select "input[name=?]", "document_appointment[appoint_to_id]"

      assert_select "input[name=?]", "document_appointment[appoint_for_id]"

      assert_select "input[name=?]", "document_appointment[appoint_by_id]"

      assert_select "input[name=?]", "document_appointment[name]"

      assert_select "input[name=?]", "document_appointment[description]"

      assert_select "input[name=?]", "document_appointment[code]"

      assert_select "input[name=?]", "document_appointment[status]"

      assert_select "input[name=?]", "document_appointment[business_type]"
    end
  end
end
