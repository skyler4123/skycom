require 'rails_helper'

RSpec.describe "roles/edit", type: :view do
  let(:role) {
    Role.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:role, role)
  end

  it "renders the edit role form" do
    render

    assert_select "form[action=?][method=?]", role_path(role), "post" do

      assert_select "input[name=?]", "role[company_id]"

      assert_select "input[name=?]", "role[name]"

      assert_select "input[name=?]", "role[description]"

      assert_select "input[name=?]", "role[code]"

      assert_select "input[name=?]", "role[status]"

      assert_select "input[name=?]", "role[business_type]"
    end
  end
end
