require 'rails_helper'

RSpec.describe "subscription_groups/edit", type: :view do
  let(:subscription_group) {
    SubscriptionGroup.create!(
      company_group: nil,
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:subscription_group, subscription_group)
  end

  it "renders the edit subscription_group form" do
    render

    assert_select "form[action=?][method=?]", subscription_group_path(subscription_group), "post" do

      assert_select "input[name=?]", "subscription_group[company_group_id]"

      assert_select "input[name=?]", "subscription_group[company_id]"

      assert_select "input[name=?]", "subscription_group[name]"

      assert_select "input[name=?]", "subscription_group[description]"

      assert_select "input[name=?]", "subscription_group[code]"

      assert_select "input[name=?]", "subscription_group[status]"

      assert_select "input[name=?]", "subscription_group[business_type]"
    end
  end
end
