require 'rails_helper'

RSpec.describe "companies/new", type: :view do
  before(:each) do
    assign(:company, Company.new(
      name: "MyString",
      user: nil,
      parent_company: nil
    ))
  end

  it "renders new company form" do
    render

    assert_select "form[action=?][method=?]", companies_path, "post" do

      assert_select "input[name=?]", "company[name]"

      assert_select "input[name=?]", "company[user_id]"

      assert_select "input[name=?]", "company[parent_company_id]"
    end
  end
end
