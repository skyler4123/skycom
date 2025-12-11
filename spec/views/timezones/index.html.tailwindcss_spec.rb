require 'rails_helper'

RSpec.describe "timezones/index", type: :view do
  before(:each) do
    assign(:timezones, [
      Timezone.create!(
        name: "Name",
        description: "Description",
        utc_offset: 2
      ),
      Timezone.create!(
        name: "Name",
        description: "Description",
        utc_offset: 2
      )
    ])
  end

  it "renders a list of timezones" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
  end
end
