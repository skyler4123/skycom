require 'rails_helper'

RSpec.describe "facilities/new", type: :view do
  before(:each) do
    assign(:facility, Facility.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new facility form" do
    render

    assert_select "form[action=?][method=?]", facilities_path, "post" do

      assert_select "input[name=?]", "facility[company_id]"

      assert_select "input[name=?]", "facility[name]"

      assert_select "input[name=?]", "facility[description]"

      assert_select "input[name=?]", "facility[code]"

      assert_select "input[name=?]", "facility[status]"

      assert_select "input[name=?]", "facility[business_type]"
    end
  end
end
