require 'rails_helper'

RSpec.describe "timezones/new", type: :view do
  before(:each) do
    assign(:timezone, Timezone.new(
      name: "MyString",
      description: "MyString",
      utc_offset: 1
    ))
  end

  it "renders new timezone form" do
    render

    assert_select "form[action=?][method=?]", timezones_path, "post" do

      assert_select "input[name=?]", "timezone[name]"

      assert_select "input[name=?]", "timezone[description]"

      assert_select "input[name=?]", "timezone[utc_offset]"
    end
  end
end
