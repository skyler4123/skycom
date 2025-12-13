require 'rails_helper'

RSpec.describe "events/new", type: :view do
  before(:each) do
    assign(:event, Event.new(
      event_group: nil,
      company_group: nil,
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new event form" do
    render

    assert_select "form[action=?][method=?]", events_path, "post" do
      assert_select "input[name=?]", "event[event_group_id]"

      assert_select "input[name=?]", "event[company_group_id]"

      assert_select "input[name=?]", "event[company_id]"

      assert_select "input[name=?]", "event[name]"

      assert_select "input[name=?]", "event[description]"

      assert_select "input[name=?]", "event[code]"

      assert_select "input[name=?]", "event[status]"

      assert_select "input[name=?]", "event[business_type]"
    end
  end
end
