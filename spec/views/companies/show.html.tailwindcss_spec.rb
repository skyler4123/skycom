require 'rails_helper'

RSpec.describe "companies/show", type: :view do
  before(:each) do
    assign(:company, Company.create!(
      user: nil,
      parent_company: nil,
      name: "Name",
      description: "Description",
      code: "Code",
      status: 2,
      ownership_type: 3,
      business_type: 4,
      currency: 5,
      registration_number: "Registration Number",
      vat_id: "Vat",
      address_line_1: "Address Line 1",
      city: "City",
      postal_code: "Postal Code",
      country: "Country",
      email: "Email",
      phone_number: "Phone Number",
      website: "Website",
      employee_count: 6,
      fiscal_year_end_month: 7
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Description/)
    expect(rendered).to match(/Code/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(/5/)
    expect(rendered).to match(/Registration Number/)
    expect(rendered).to match(/Vat/)
    expect(rendered).to match(/Address Line 1/)
    expect(rendered).to match(/City/)
    expect(rendered).to match(/Postal Code/)
    expect(rendered).to match(/Country/)
    expect(rendered).to match(/Email/)
    expect(rendered).to match(/Phone Number/)
    expect(rendered).to match(/Website/)
    expect(rendered).to match(/6/)
    expect(rendered).to match(/7/)
  end
end
