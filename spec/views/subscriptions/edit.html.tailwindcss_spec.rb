require 'rails_helper'

RSpec.describe "subscriptions/edit", type: :view do
  let(:subscription) {
    Subscription.create!(
      subscription_group: nil,
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
    assign(:subscription, subscription)
  end

  it "renders the edit subscription form" do
    render

    assert_select "form[action=?][method=?]", subscription_path(subscription), "post" do

      assert_select "input[name=?]", "subscription[subscription_group_id]"

      assert_select "input[name=?]", "subscription[company_group_id]"

      assert_select "input[name=?]", "subscription[company_id]"

      assert_select "input[name=?]", "subscription[name]"

      assert_select "input[name=?]", "subscription[description]"

      assert_select "input[name=?]", "subscription[code]"

      assert_select "input[name=?]", "subscription[status]"

      assert_select "input[name=?]", "subscription[business_type]"
    end
  end
end
