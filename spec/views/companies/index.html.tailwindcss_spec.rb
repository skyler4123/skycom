require 'rails_helper'

RSpec.describe "companies/index", type: :view do
  before(:each) do
    assign(:companies, [
      Company.create!(
        user: nil,
        parent_company: nil,
        name: "Name",
        description: "Description",
        status: 2,
        ownership_type: 3,
        business_type: 4,
        registration_number: "Registration Number",
        vat_id: "Vat",
        address_line_1: "Address Line 1",
        city: "City",
        postal_code: "Postal Code",
        country: "Country",
        email: "Email",
        phone_number: "Phone Number",
        website: "Website",
        employee_count: 5,
        fiscal_year_end_month: 6
      ),
      Company.create!(
        user: nil,
        parent_company: nil,
        name: "Name",
        description: "Description",
        status: 2,
        ownership_type: 3,
        business_type: 4,
        registration_number: "Registration Number",
        vat_id: "Vat",
        address_line_1: "Address Line 1",
        city: "City",
        postal_code: "Postal Code",
        country: "Country",
        email: "Email",
        phone_number: "Phone Number",
        website: "Website",
        employee_count: 5,
        fiscal_year_end_month: 6
      )
    ])
  end

  it "renders a list of companies" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Description".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Registration Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Vat".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Address Line 1".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("City".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Postal Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Country".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Email".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Phone Number".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Website".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(5.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(6.to_s), count: 2
  end
end
