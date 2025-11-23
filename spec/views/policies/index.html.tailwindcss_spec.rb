require 'rails_helper'

RSpec.describe "policies/index", type: :view do
  before(:each) do
    assign(:policies, [
      Policy.create!(
        company: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        resource: "Resource",
        action: "Action",
        status: 2,
        business_type: 3
      ),
      Policy.create!(
        company: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        resource: "Resource",
        action: "Action",
        status: 2,
        business_type: 3
      )
    ])
  end

  it "renders a list of policies" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Resource".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Action".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
  end
end
