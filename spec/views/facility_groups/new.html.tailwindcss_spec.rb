require 'rails_helper'

RSpec.describe "facility_groups/new", type: :view do
  before(:each) do
    assign(:facility_group, FacilityGroup.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new facility_group form" do
    render

    assert_select "form[action=?][method=?]", facility_groups_path, "post" do

      assert_select "input[name=?]", "facility_group[company_id]"

      assert_select "input[name=?]", "facility_group[name]"

      assert_select "input[name=?]", "facility_group[description]"

      assert_select "input[name=?]", "facility_group[code]"

      assert_select "input[name=?]", "facility_group[status]"

      assert_select "input[name=?]", "facility_group[business_type]"
    end
  end
end
