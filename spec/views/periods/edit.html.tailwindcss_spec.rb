require 'rails_helper'

RSpec.describe "periods/edit", type: :view do
  let(:period) {
    Period.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      duration: 1
    )
  }

  before(:each) do
    assign(:period, period)
  end

  it "renders the edit period form" do
    render

    assert_select "form[action=?][method=?]", period_path(period), "post" do

      assert_select "input[name=?]", "period[company_id]"

      assert_select "input[name=?]", "period[name]"

      assert_select "input[name=?]", "period[description]"

      assert_select "input[name=?]", "period[code]"

      assert_select "input[name=?]", "period[duration]"
    end
  end
end
