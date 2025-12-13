require 'rails_helper'

RSpec.describe "notification_groups/edit", type: :view do
  let(:notification_group) {
    NotificationGroup.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:notification_group, notification_group)
  end

  it "renders the edit notification_group form" do
    render

    assert_select "form[action=?][method=?]", notification_group_path(notification_group), "post" do
      assert_select "input[name=?]", "notification_group[company_id]"

      assert_select "input[name=?]", "notification_group[name]"

      assert_select "input[name=?]", "notification_group[description]"

      assert_select "input[name=?]", "notification_group[code]"

      assert_select "input[name=?]", "notification_group[status]"

      assert_select "input[name=?]", "notification_group[business_type]"
    end
  end
end
