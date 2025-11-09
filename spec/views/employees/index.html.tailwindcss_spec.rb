require 'rails_helper'

RSpec.describe "employees/index", type: :view do
  before(:each) do
    assign(:employees, [
      Employee.create!(
        name: "Name",
        user: nil,
        company: nil
      ),
      Employee.create!(
        name: "Name",
        user: nil,
        company: nil
      )
    ])
  end

  it "renders a list of employees" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
