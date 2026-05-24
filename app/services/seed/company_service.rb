class Seed::CompanyService
  RESOURCE_NAMES = {
    retail: %w[Product Order Customer Employee Branch Department PolicyAppointment Invoice Payment Service Category PropertyMapping Brand Facility],
    restaurant: %w[Product Order Customer Employee Branch Department PolicyAppointment Invoice Payment Service Table Reservation Brand Facility],
    hotel: %w[Product Order Customer Employee Branch Department PolicyAppointment Invoice Payment Service Room Booking Guest Brand Facility],
    hospital: %w[Product Order Customer Employee Branch Department PolicyAppointment Invoice Payment Service Patient Appointment Brand Facility],
    education: %w[Product Order Customer Employee Branch Department PolicyAppointment Invoice Payment Service Course Student Exam Brand Facility],
    fitness: %w[Product Order Customer Employee Branch Department PolicyAppointment Invoice Payment Service Membership Booking Brand Facility]
  }.freeze

  def self.new(
    user:,
    email: "company_#{SecureRandom.hex}@gmail.com",
    name: Faker::Name.name,
    description: Faker::Company.catch_phrase,
    lifecycle_status: Company.lifecycle_statuses.keys.sample,
    workflow_status: Company.workflow_statuses.keys.sample,
    ownership_type: Company.ownership_types.keys.sample,
    business_type: Company.business_types.keys.sample,
    currency_code: Company.currency_codes.keys.sample,
    registration_number: Faker::Company.ein,
    vat_id: Faker::Code.npi,
    timezone: Company.timezones.keys.sample,
    employee_count: rand(10..5000),
    address_line_1: Faker::Address.street_address,
    city: Faker::Address.city,
    postal_code: Faker::Address.postcode,
    country_code: Company.country_codes.keys.sample,
    phone_number: Faker::PhoneNumber.phone_number,
    website: Faker::Internet.url,
    fiscal_year_end_month: Company.fiscal_year_end_months.keys.sample,
    resource_names: RESOURCE_NAMES[business_type] || RESOURCE_NAMES[:retail],
    discarded_at: nil
  )
    Company.new(
      user: user,
      name: name,
      description: description,
      lifecycle_status: lifecycle_status,
      workflow_status: workflow_status,
      ownership_type: ownership_type,
      business_type: business_type,
      currency_code: currency_code,
      registration_number: registration_number,
      vat_id: vat_id,
      timezone: timezone,
      employee_count: employee_count,
      address_line_1: address_line_1,
      city: city,
      postal_code: postal_code,
      country_code: country_code,
      email: email,
      phone_number: phone_number,
      website: website,
      fiscal_year_end_month: fiscal_year_end_month,
      resource_names: resource_names,
      discarded_at: discarded_at
    )
  end

  def self.create(...)
    company = new(...)
    company.save!
    company
  end
end
