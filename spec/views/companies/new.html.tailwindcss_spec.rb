require 'rails_helper'

RSpec.describe "companies/new", type: :view do
  before(:each) do
    assign(:company, Company.new(
      user: nil,
      parent_company: nil,
      name: "MyString",
      description: "MyString",
      status: 1,
      kind: 1
    ))
  end

  it "renders new company form" do
    render

    assert_select "form[action=?][method=?]", companies_path, "post" do

      assert_select "input[name=?]", "company[user_id]"

      assert_select "input[name=?]", "company[parent_company_id]"

      assert_select "input[name=?]", "company[name]"

      assert_select "input[name=?]", "company[description]"

      assert_select "input[name=?]", "company[status]"

      assert_select "input[name=?]", "company[kind]"
    end
  end
end
