require 'rails_helper'

RSpec.describe "invoices/index", type: :view do
  before(:each) do
    assign(:invoices, [
      Invoice.create!(
        order: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        currency: 2,
        duration: 3,
        number: "Number",
        total: "Total",
        status: 4,
        business_type: 5
      ),
      Invoice.create!(
        order: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        currency: 2,
        duration: 3,
        number: "Number",
        total: "Total",
        status: 4,
        business_type: 5
      )
    ])
  end

  it "renders a list of invoices" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Total".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(5.to_s), count: 2
  end
end
