require 'rails_helper'

RSpec.describe "subscription_appointments/new", type: :view do
  before(:each) do
    assign(:subscription_appointment, SubscriptionAppointment.new(
      subscription: nil,
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

  it "renders new subscription_appointment form" do
    render

    assert_select "form[action=?][method=?]", subscription_appointments_path, "post" do
      assert_select "input[name=?]", "subscription_appointment[subscription_id]"

      assert_select "input[name=?]", "subscription_appointment[appoint_from_id]"

      assert_select "input[name=?]", "subscription_appointment[appoint_to_id]"

      assert_select "input[name=?]", "subscription_appointment[appoint_for_id]"

      assert_select "input[name=?]", "subscription_appointment[appoint_by_id]"

      assert_select "input[name=?]", "subscription_appointment[name]"

      assert_select "input[name=?]", "subscription_appointment[description]"

      assert_select "input[name=?]", "subscription_appointment[code]"

      assert_select "input[name=?]", "subscription_appointment[status]"

      assert_select "input[name=?]", "subscription_appointment[business_type]"
    end
  end
end
