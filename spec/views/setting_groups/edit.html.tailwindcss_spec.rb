require 'rails_helper'

RSpec.describe "setting_groups/edit", type: :view do
  let(:setting_group) {
    SettingGroup.create!(
      company_group: nil,
      company: nil,
      content: "",
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:setting_group, setting_group)
  end

  it "renders the edit setting_group form" do
    render

    assert_select "form[action=?][method=?]", setting_group_path(setting_group), "post" do

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
