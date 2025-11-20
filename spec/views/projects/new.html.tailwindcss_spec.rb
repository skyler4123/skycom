require 'rails_helper'

RSpec.describe "projects/new", type: :view do
  before(:each) do
    assign(:project, Project.new(
      company: nil,
      project_group: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    ))
  end

  it "renders new project form" do
    render

    assert_select "form[action=?][method=?]", projects_path, "post" do

      assert_select "input[name=?]", "project[company_id]"

      assert_select "input[name=?]", "project[project_group_id]"

      assert_select "input[name=?]", "project[name]"

      assert_select "input[name=?]", "project[description]"

      assert_select "input[name=?]", "project[code]"

      assert_select "input[name=?]", "project[status]"

      assert_select "input[name=?]", "project[business_type]"
    end
  end
end
