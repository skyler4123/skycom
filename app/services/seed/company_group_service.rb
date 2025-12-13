# This service seeds the database with Company records, ensuring each company
# is associated with an existing User and populating all new fields
# (enums, addresses, registration info).

class Seed::CompanyGroupService
  def self.create(
    user:,
    name: nil,
    description: Faker::Company.catch_phrase,
    status: nil,
    ownership_type: nil,
    business_type:,
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
    base_name = Faker::Company.unique.name
    name ||= "#{base_name} #{business_type.to_s.titleize}"
    domain_suffix = (business_type == :university || business_type == :school) ? ".edu" : ".com"
    timezone = CompanyGroup.timezones.keys.sample
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..365).days : nil

    CompanyGroup.create!(
      user: user,
      name: name,
      description: description,
      status: status || Company.statuses.keys.sample,
      ownership_type: ownership_type || Company.ownership_types.keys.sample,
      business_type: business_type,
      currency: currency || Company.currencies.keys.sample,
      registration_number: registration_number,
      vat_id: vat_id,
      timezone: timezone,
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
