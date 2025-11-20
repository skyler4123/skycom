require 'rails_helper'

RSpec.describe "periods/index", type: :view do
  before(:each) do
    assign(:periods, [
      Period.create!(
        company: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        duration: 2
      ),
      Period.create!(
        company: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        duration: 2
      )
    ])
  end

  it "renders a list of periods" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
  end
end
