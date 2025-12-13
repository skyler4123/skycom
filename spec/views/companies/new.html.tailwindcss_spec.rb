require 'rails_helper'

RSpec.describe "companies/new", type: :view do
  before(:each) do
    assign(:company, Company.new(
      company_group: nil,
      parent_company: nil,
      name: "MyString",
      description: "MyString",
      code: "MyString",
      status: 1,
      ownership_type: 1,
      business_type: 1,
      currency: 1,
      registration_number: "MyString",
      vat_id: "MyString",
      address_line_1: "MyString",
      city: "MyString",
      postal_code: "MyString",
      country: "MyString",
      email: "MyString",
      phone_number: "MyString",
      website: "MyString",
      employee_count: 1,
      fiscal_year_end_month: 1
    ))
  end

  it "renders new company form" do
    render

    assert_select "form[action=?][method=?]", companies_path, "post" do
      assert_select "input[name=?]", "company[company_group_id]"

      assert_select "input[name=?]", "company[parent_company_id]"

      assert_select "input[name=?]", "company[name]"

      assert_select "input[name=?]", "company[description]"

      assert_select "input[name=?]", "company[code]"

      assert_select "input[name=?]", "company[status]"

      assert_select "input[name=?]", "company[ownership_type]"

      assert_select "input[name=?]", "company[business_type]"

      assert_select "input[name=?]", "company[currency]"

      assert_select "input[name=?]", "company[registration_number]"

      assert_select "input[name=?]", "company[vat_id]"

      assert_select "input[name=?]", "company[address_line_1]"

      assert_select "input[name=?]", "company[city]"

      assert_select "input[name=?]", "company[postal_code]"

      assert_select "input[name=?]", "company[country]"

      assert_select "input[name=?]", "company[email]"

      assert_select "input[name=?]", "company[phone_number]"

      assert_select "input[name=?]", "company[website]"

      assert_select "input[name=?]", "company[employee_count]"

      assert_select "input[name=?]", "company[fiscal_year_end_month]"
    end
  end
end
