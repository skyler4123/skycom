require 'rails_helper'

RSpec.describe "companies/index", type: :view do
  before(:each) do
    assign(:companies, [
      Company.create!(
        user: nil,
        parent_company: nil,
        name: "Name",
        description: "Description"
      ),
      Company.create!(
        user: nil,
        parent_company: nil,
        name: "Name",
        description: "Description"
      )
    ])
  end

  it "renders a list of companies" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
  end
end
