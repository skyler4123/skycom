require 'rails_helper'

RSpec.describe "service_groups/edit", type: :view do
  let(:service_group) {
    ServiceGroup.create!(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      duration: 1,
      business_type: 1
    )
  }

  before(:each) do
    assign(:service_group, service_group)
  end

  it "renders the edit service_group form" do
    render

    assert_select "form[action=?][method=?]", service_group_path(service_group), "post" do

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
