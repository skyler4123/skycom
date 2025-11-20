require 'rails_helper'

RSpec.describe "project_groups/edit", type: :view do
  let(:project_group) {
    ProjectGroup.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:project_group, project_group)
  end

  it "renders the edit project_group form" do
    render

    assert_select "form[action=?][method=?]", project_group_path(project_group), "post" do

      assert_select "input[name=?]", "project_group[company_id]"

      assert_select "input[name=?]", "project_group[name]"

      assert_select "input[name=?]", "project_group[description]"

      assert_select "input[name=?]", "project_group[code]"

      assert_select "input[name=?]", "project_group[status]"

      assert_select "input[name=?]", "project_group[business_type]"
    end
  end
end
