require 'rails_helper'

RSpec.describe "projects/edit", type: :view do
  let(:project) {
    Project.create!(
      company: nil,
      project_group: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:project, project)
  end

  it "renders the edit project form" do
    render

    assert_select "form[action=?][method=?]", project_path(project), "post" do

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
