require 'rails_helper'

RSpec.describe "assessments/new", type: :view do
  before(:each) do
    assign(:assessment, Assessment.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new assessment form" do
    render

    assert_select "form[action=?][method=?]", assessments_path, "post" do

      assert_select "input[name=?]", "assessment[company_id]"

      assert_select "input[name=?]", "assessment[name]"

      assert_select "input[name=?]", "assessment[description]"

      assert_select "input[name=?]", "assessment[code]"

      assert_select "input[name=?]", "assessment[status]"

      assert_select "input[name=?]", "assessment[business_type]"
    end
  end
end
