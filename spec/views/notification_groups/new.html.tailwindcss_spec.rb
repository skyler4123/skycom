require 'rails_helper'

RSpec.describe "notification_groups/new", type: :view do
  before(:each) do
    assign(:notification_group, NotificationGroup.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new notification_group form" do
    render

    assert_select "form[action=?][method=?]", notification_groups_path, "post" do

      assert_select "input[name=?]", "notification_group[company_id]"

      assert_select "input[name=?]", "notification_group[name]"

      assert_select "input[name=?]", "notification_group[description]"

      assert_select "input[name=?]", "notification_group[code]"

      assert_select "input[name=?]", "notification_group[status]"

      assert_select "input[name=?]", "notification_group[business_type]"
    end
  end
end
