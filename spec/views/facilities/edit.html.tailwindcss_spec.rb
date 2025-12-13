require 'rails_helper'

RSpec.describe "facilities/edit", type: :view do
  let(:facility) {
    Facility.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:facility, facility)
  end

  it "renders the edit facility form" do
    render

    assert_select "form[action=?][method=?]", facility_path(facility), "post" do
      assert_select "input[name=?]", "facility[company_id]"

      assert_select "input[name=?]", "facility[name]"

      assert_select "input[name=?]", "facility[description]"

      assert_select "input[name=?]", "facility[code]"

      assert_select "input[name=?]", "facility[status]"

      assert_select "input[name=?]", "facility[business_type]"
    end
  end
end
