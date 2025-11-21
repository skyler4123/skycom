require 'rails_helper'

RSpec.describe "notifications/edit", type: :view do
  let(:notification) {
    Notification.create!(
      notification: nil,
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:notification, notification)
  end

  it "renders the edit notification form" do
    render

    assert_select "form[action=?][method=?]", notification_path(notification), "post" do

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
