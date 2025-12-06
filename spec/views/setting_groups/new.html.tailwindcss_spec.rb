require 'rails_helper'

RSpec.describe "setting_groups/new", type: :view do
  before(:each) do
    assign(:setting_group, SettingGroup.new(
      company_group: nil,
      company: nil,
      content: "",
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new setting_group form" do
    render

    assert_select "form[action=?][method=?]", setting_groups_path, "post" do

      assert_select "input[name=?]", "setting_group[company_group_id]"

      assert_select "input[name=?]", "setting_group[company_id]"

      assert_select "input[name=?]", "setting_group[content]"

      assert_select "input[name=?]", "setting_group[name]"

      assert_select "input[name=?]", "setting_group[description]"

      assert_select "input[name=?]", "setting_group[code]"

      assert_select "input[name=?]", "setting_group[status]"

      assert_select "input[name=?]", "setting_group[business_type]"
    end
  end
end
