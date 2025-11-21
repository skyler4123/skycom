require 'rails_helper'

RSpec.describe "notifications/new", type: :view do
  before(:each) do
    assign(:notification, Notification.new(
      notification: nil,
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new notification form" do
    render

    assert_select "form[action=?][method=?]", notifications_path, "post" do

      assert_select "input[name=?]", "notification[notification_id]"

      assert_select "input[name=?]", "notification[company_id]"

      assert_select "input[name=?]", "notification[name]"

      assert_select "input[name=?]", "notification[description]"

      assert_select "input[name=?]", "notification[code]"

      assert_select "input[name=?]", "notification[status]"

      assert_select "input[name=?]", "notification[business_type]"
    end
  end
end
