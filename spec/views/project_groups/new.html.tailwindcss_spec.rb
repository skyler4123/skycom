require 'rails_helper'

RSpec.describe "project_groups/new", type: :view do
  before(:each) do
    assign(:project_group, ProjectGroup.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new project_group form" do
    render

    assert_select "form[action=?][method=?]", project_groups_path, "post" do
      assert_select "input[name=?]", "project_group[company_id]"

      assert_select "input[name=?]", "project_group[name]"

      assert_select "input[name=?]", "project_group[description]"

      assert_select "input[name=?]", "project_group[code]"

      assert_select "input[name=?]", "project_group[status]"

      assert_select "input[name=?]", "project_group[business_type]"
    end
  end
end
