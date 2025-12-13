require 'rails_helper'

RSpec.describe "service_groups/new", type: :view do
  before(:each) do
    assign(:service_group, ServiceGroup.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      duration: 1,
      business_type: 1
    ))
  end

  it "renders new service_group form" do
    render

    assert_select "form[action=?][method=?]", service_groups_path, "post" do
      assert_select "input[name=?]", "service_group[company_id]"

      assert_select "input[name=?]", "service_group[name]"

      assert_select "input[name=?]", "service_group[description]"

      assert_select "input[name=?]", "service_group[code]"

      assert_select "input[name=?]", "service_group[status]"

      assert_select "input[name=?]", "service_group[duration]"

      assert_select "input[name=?]", "service_group[business_type]"
    end
  end
end
