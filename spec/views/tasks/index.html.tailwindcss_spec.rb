require 'rails_helper'

RSpec.describe "tasks/index", type: :view do
  before(:each) do
    assign(:tasks, [
      Task.create!(
        company: nil,
        task_group: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        currency: 2,
        status: 3,
        business_type: 4
      ),
      Task.create!(
        company: nil,
        task_group: nil,
        name: "Name",
        description: "Description",
        code: "Code",
        currency: 2,
        status: 3,
        business_type: 4
      )
    ])
  end

  it "renders a list of tasks" do
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
  end
end
