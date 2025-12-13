require 'rails_helper'

RSpec.describe "settings/new", type: :view do
  before(:each) do
    assign(:setting, Setting.new(
      setting_group: nil,
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

  it "renders new setting form" do
    render

    assert_select "form[action=?][method=?]", settings_path, "post" do
      assert_select "input[name=?]", "setting[setting_group_id]"

      assert_select "input[name=?]", "setting[company_group_id]"

      assert_select "input[name=?]", "setting[company_id]"

      assert_select "input[name=?]", "setting[content]"

      assert_select "input[name=?]", "setting[name]"

      assert_select "input[name=?]", "setting[description]"

      assert_select "input[name=?]", "setting[code]"

      assert_select "input[name=?]", "setting[status]"

      assert_select "input[name=?]", "setting[business_type]"
    end
  end
end
