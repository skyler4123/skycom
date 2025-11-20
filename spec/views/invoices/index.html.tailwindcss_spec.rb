require 'rails_helper'

RSpec.describe "invoices/index", type: :view do
  before(:each) do
    assign(:invoices, [
      Invoice.create!(
        order: nil,
        name: "Name",
        description: "Description",
        currency: "Currency",
        number: "Number",
        total: "Total",
        status: 2,
        business_type: 3
      ),
      Invoice.create!(
        order: nil,
        name: "Name",
        description: "Description",
        currency: "Currency",
        number: "Number",
        total: "Total",
        status: 2,
        business_type: 3
      )
    ])
  end

  it "renders a list of invoices" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Currency".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Total".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
  end
end
