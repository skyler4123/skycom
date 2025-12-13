require 'rails_helper'

RSpec.describe "periods/new", type: :view do
  before(:each) do
    assign(:period, Period.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      duration: 1
    ))
  end

  it "renders new period form" do
    render

    assert_select "form[action=?][method=?]", periods_path, "post" do
      assert_select "input[name=?]", "period[company_id]"

      assert_select "input[name=?]", "period[name]"

      assert_select "input[name=?]", "period[description]"

      assert_select "input[name=?]", "period[code]"

      assert_select "input[name=?]", "period[duration]"
    end
  end
end
