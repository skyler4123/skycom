require 'rails_helper'

RSpec.describe "project_groups/index", type: :view do
  before(:each) do
    assign(:project_groups, [
      ProjectGroup.create!(
        company: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        status: 2,
        business_type: 3
      ),
      ProjectGroup.create!(
        company: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        status: 2,
        business_type: 3
      )
    ])
  end

  it "renders a list of project_groups" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
  end
end
