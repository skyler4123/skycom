require 'rails_helper'

RSpec.describe "company_groups/new", type: :view do
  before(:each) do
    assign(:company_group, CompanyGroup.new(
      user: nil,
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

  it "renders new company_group form" do
    render

    assert_select "form[action=?][method=?]", company_groups_path, "post" do

      assert_select "input[name=?]", "company_group[user_id]"

      assert_select "input[name=?]", "company_group[name]"

      assert_select "input[name=?]", "company_group[description]"

      assert_select "input[name=?]", "company_group[code]"

      assert_select "input[name=?]", "company_group[status]"

      assert_select "input[name=?]", "company_group[ownership_type]"

      assert_select "input[name=?]", "company_group[business_type]"

      assert_select "input[name=?]", "company_group[currency]"

      assert_select "input[name=?]", "company_group[registration_number]"

      assert_select "input[name=?]", "company_group[vat_id]"

      assert_select "input[name=?]", "company_group[address_line_1]"

      assert_select "input[name=?]", "company_group[city]"

      assert_select "input[name=?]", "company_group[postal_code]"

      assert_select "input[name=?]", "company_group[country]"

      assert_select "input[name=?]", "company_group[email]"

      assert_select "input[name=?]", "company_group[phone_number]"

      assert_select "input[name=?]", "company_group[website]"

      assert_select "input[name=?]", "company_group[employee_count]"

      assert_select "input[name=?]", "company_group[fiscal_year_end_month]"
    end
  end
end
