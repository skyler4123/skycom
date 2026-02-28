# This service seeds the database with Company records, ensuring each company
# is associated with an existing User and populating all new fields
# (enums, addresses, registration info).

class Seed::BranchService
  def self.create(
    company:,
    name: Faker::Name.name,
    description: Faker::Company.catch_phrase,
    lifecycle_status: Branch.lifecycle_statuses.keys.sample,
    workflow_status: Branch.workflow_statuses.keys.sample,
    ownership_type: Branch.ownership_types.keys.sample,
    business_type: Branch.business_types.keys.sample,
    currency_code: Branch.currency_codes.keys.sample,
    registration_number: Faker::Company.ein,
    vat_id: Faker::Code.npi,
    employee_count: rand(10..5000),
    address_line_1: Faker::Address.street_address,
    city: Faker::Address.city,
    postal_code: Faker::Address.postcode,
    country_code: Branch.country_codes.keys.sample,
    email: Faker::Internet.email,
    phone_number: Faker::PhoneNumber.phone_number,
    website: Faker::Internet.url,
    fiscal_year_end_month: Branch.fiscal_year_end_months.keys.sample,
    discarded_at: nil
  )
    Branch.create!(
      company: company,
      name: name,
      description: description,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      ownership_type: ownership_type,
      business_type: business_type,
      currency_code: currency_code,
      registration_number: registration_number,
      vat_id: vat_id,
      employee_count: employee_count,
      address_line_1: address_line_1,
      city: city,
      postal_code: postal_code,
      country_code: country_code,
      email: email,
      phone_number: phone_number,
      website: website,
      fiscal_year_end_month: fiscal_year_end_month,
      discarded_at: discarded_at
    )
  end
end
