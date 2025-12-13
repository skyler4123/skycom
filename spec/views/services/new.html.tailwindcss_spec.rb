require 'rails_helper'

RSpec.describe "services/new", type: :view do
  before(:each) do
    assign(:service, Service.new(
      company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      duration: 1,
      business_type: 1
    ))
  end

  it "renders new service form" do
    render

    assert_select "form[action=?][method=?]", services_path, "post" do
      assert_select "input[name=?]", "service[company_id]"

      assert_select "input[name=?]", "service[name]"

      assert_select "input[name=?]", "service[description]"

      assert_select "input[name=?]", "service[code]"

      assert_select "input[name=?]", "service[status]"

      assert_select "input[name=?]", "service[duration]"

      assert_select "input[name=?]", "service[business_type]"
    end
  end
end
