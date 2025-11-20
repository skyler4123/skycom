require 'rails_helper'

RSpec.describe "facility_groups/edit", type: :view do
  let(:facility_group) {
    FacilityGroup.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:facility_group, facility_group)
  end

  it "renders the edit facility_group form" do
    render

    assert_select "form[action=?][method=?]", facility_group_path(facility_group), "post" do

      assert_select "input[name=?]", "facility_group[company_id]"

      assert_select "input[name=?]", "facility_group[name]"

      assert_select "input[name=?]", "facility_group[description]"

      assert_select "input[name=?]", "facility_group[code]"

      assert_select "input[name=?]", "facility_group[status]"

      assert_select "input[name=?]", "facility_group[business_type]"
    end
  end
end
