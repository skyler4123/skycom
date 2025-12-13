require 'rails_helper'

RSpec.describe "timezones/edit", type: :view do
  let(:timezone) {
    Timezone.create!(
      name: "MyString",
      description: "MyString",
      utc_offset: 1
    )
  }

  before(:each) do
    assign(:timezone, timezone)
  end

  it "renders the edit timezone form" do
    render

    assert_select "form[action=?][method=?]", timezone_path(timezone), "post" do
      assert_select "input[name=?]", "timezone[name]"

      assert_select "input[name=?]", "timezone[description]"

      assert_select "input[name=?]", "timezone[utc_offset]"
    end
  end
end
