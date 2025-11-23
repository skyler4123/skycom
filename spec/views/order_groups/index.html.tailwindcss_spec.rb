require 'rails_helper'

RSpec.describe "order_groups/index", type: :view do
  before(:each) do
    assign(:order_groups, [
      OrderGroup.create!(
        company: nil,
        customer: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        currency: 2,
        duration: 3,
        status: 4,
        business_type: 5
      ),
      OrderGroup.create!(
        company: nil,
        customer: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        currency: 2,
        duration: 3,
        status: 4,
        business_type: 5
      )
    ])
  end

  it "renders a list of order_groups" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(5.to_s), count: 2
  end
end
