# This service seeds the database with Company records, ensuring each company
# is associated with an existing User and populating all new fields
# (enums, addresses, registration info).

class Seed::CompanyService
  def self.create(
    company_group:,
    parent_company: nil,
    name: nil,
    description: Faker::Company.catch_phrase,
    lifecycle_status: nil,
    workflow_status: nil,
    ownership_type: nil,
    business_type: nil,
    currency: nil,
    registration_number: Faker::Company.ein,
    vat_id: Faker::Code.npi,
    employee_count: rand(10..5000),
    address_line_1: Faker::Address.street_address,
    city: Faker::Address.city,
    postal_code: Faker::Address.postcode,
    country: Faker::Address.country,
    email: nil,
    phone_number: Faker::PhoneNumber.phone_number,
    website: nil,
    fiscal_year_end_month: nil,
    discarded_at: nil
  )
    business_type = Company.business_types.keys.sample if business_type.nil?
    base_name = Faker::Company.unique.name
    name ||= "#{base_name} #{business_type.to_s.titleize}"
    domain_suffix = (business_type == :university || business_type == :school) ? ".edu" : ".com"

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..365).days : nil

    Company.create!(
      company_group: company_group,
      parent_company: parent_company,
      name: name,
      description: description,
      lifecycle_status: lifecycle_status || Company.lifecycle_statuses.keys.sample,
      workflow_status: workflow_status || Company.workflow_statuses.keys.sample,
      ownership_type: ownership_type || Company.ownership_types.keys.sample,
      business_type: business_type,
      currency: currency || Company.currencies.keys.sample,
      registration_number: registration_number,
      vat_id: vat_id,
      employee_count: employee_count,
      address_line_1: address_line_1,
      city: city,
      postal_code: postal_code,
      country: country,
      email: email || Faker::Internet.email(name: base_name),
      phone_number: phone_number,
      website: website || Faker::Internet.url(host: base_name.parameterize + domain_suffix),
      fiscal_year_end_month: fiscal_year_end_month || Company.fiscal_year_end_months.keys.sample,
      discarded_at: discarded_at
    )
  end
end
