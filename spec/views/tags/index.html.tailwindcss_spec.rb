require 'rails_helper'

RSpec.describe "tags/index", type: :view do
  before(:each) do
    assign(:tags, [
      Tag.create!(
        company: nil,
        name: "Name",
        description: "Description"
      ),
      Tag.create!(
        company: nil,
        name: "Name",
        description: "Description"
      )
    ])
  end

  it "renders a list of tags" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
  end
end
