require 'rails_helper'

RSpec.describe "event_groups/edit", type: :view do
  let(:event_group) {
    EventGroup.create!(
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
    assign(:event_group, event_group)
  end

  it "renders the edit event_group form" do
    render

    assert_select "form[action=?][method=?]", event_group_path(event_group), "post" do

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
