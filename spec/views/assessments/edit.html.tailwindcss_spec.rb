require 'rails_helper'

RSpec.describe "assessments/edit", type: :view do
  let(:assessment) {
    Assessment.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:assessment, assessment)
  end

  it "renders the edit assessment form" do
    render

    assert_select "form[action=?][method=?]", assessment_path(assessment), "post" do

      assert_select "input[name=?]", "assessment[company_id]"

      assert_select "input[name=?]", "assessment[name]"

      assert_select "input[name=?]", "assessment[description]"

      assert_select "input[name=?]", "assessment[code]"

      assert_select "input[name=?]", "assessment[status]"

      assert_select "input[name=?]", "assessment[business_type]"
    end
  end
end
