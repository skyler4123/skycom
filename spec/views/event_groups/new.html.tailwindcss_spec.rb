require 'rails_helper'

RSpec.describe "event_groups/new", type: :view do
  before(:each) do
    assign(:event_group, EventGroup.new(
      company_group: nil,
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new event_group form" do
    render

    assert_select "form[action=?][method=?]", event_groups_path, "post" do

      assert_select "input[name=?]", "event_group[company_group_id]"

      assert_select "input[name=?]", "event_group[company_id]"

      assert_select "input[name=?]", "event_group[name]"

      assert_select "input[name=?]", "event_group[description]"

      assert_select "input[name=?]", "event_group[code]"

      assert_select "input[name=?]", "event_group[status]"

      assert_select "input[name=?]", "event_group[business_type]"
    end
  end
end
