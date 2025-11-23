# This service seeds the database with Company records, ensuring each company
# is associated with an existing User and populating all new fields 
# (enums, addresses, registration info).

class Seed::CompanyService
  # Configuration for the number of companies per user
  COMPANIES_PER_USER = 3
  
  # Business types to cycle through when seeding, focusing on the Education sector.
  # Add or remove types here to control the seeded data mix.
  BUSINESS_TYPE_CYCLE = %i[school].freeze
  
  def self.run
    puts "Seeding Company records..."
  
    # Get all available enum keys for random assignment
    statuses = Company.statuses.keys
    ownership_types = Company.ownership_types.keys
    fiscal_months = Company.fiscal_year_end_months.keys
    currencies = Company.currencies.keys
  
    total_companies_created = 0

    User.all.each do |user|
      # Collect all companies created by this user so far to serve as potential parents
      user_companies = [] 

      COMPANIES_PER_USER.times do |n|
        # Determine the business type by cycling through the defined array
        cycled_business_type = BUSINESS_TYPE_CYCLE[n % BUSINESS_TYPE_CYCLE.length]
        
        # 1. Randomly pick enum values
        random_status = statuses.sample
        random_ownership = ownership_types.sample
        random_fiscal_month = fiscal_months.sample
        random_currency = currencies.sample
        
        # 2. Randomly select a parent company from those already created by this user
        parent = user_companies.sample 
        
        # 3. Randomly discard about 1 in 10 records
        should_discard = rand(10) == 0
        
        # Generate a consistent name base for URL/Email, and a friendly name tag
        base_name = Faker::Company.unique.name
        company_name_tag = "#{base_name} #{cycled_business_type.to_s.titleize} ##{user.id}-#{n + 1}"
        
        # Determine domain extension based on type
        domain_suffix = (cycled_business_type == :university || cycled_business_type == :school) ? ".edu" : ".com"
        
        company = user.companies.create!(
          # Associations
          parent_company: parent,
          
          # Core Attributes
          name: company_name_tag,
          description: Faker::Company.catch_phrase,
          
          # Enums
          status: random_status,
          ownership_type: random_ownership,
          business_type: cycled_business_type, # <-- NOW CYCLED
          
          # Currency
          currency: random_currency,
          
          # Administrative Fields
          registration_number: Faker::Company.ein,
          vat_id: Faker::Code.npi,
          employee_count: rand(10..5000),

          # Contact & Address Fields
          address_line_1: Faker::Address.street_address,
          city: Faker::Address.city,
          postal_code: Faker::Address.postcode,
          country: Faker::Address.country,
          email: Faker::Internet.email(name: base_name),
          phone_number: Faker::PhoneNumber.phone_number,
          website: Faker::Internet.url(host: base_name.parameterize + domain_suffix),
          
          # Operational Fields
          fiscal_year_end_month: random_fiscal_month,
          
          # Soft Deletion
          discarded_at: should_discard ? Time.zone.now - rand(1..365).days : nil
        )
        
        user_companies << company # Add to list for potential parent assignment
        total_companies_created += 1
      end
    end
    
    puts "Successfully created #{total_companies_created} Company records."
    rescue => e
    puts "Error during Company seeding: #{e.message}"
    # Re-raise the error to halt the seed process if needed
    raise
  end

  def self.create(
    user: User.all.sample,
    parent_company: nil,
    name: nil,
    description: Faker::Company.catch_phrase,
    status: nil,
    ownership_type: nil,
    business_type: BUSINESS_TYPE_CYCLE.sample,
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
    raise "Cannot create a company: No users exist to own it." if user.nil?

    base_name = Faker::Company.unique.name
    name ||= "#{base_name} #{business_type.to_s.titleize}"
    domain_suffix = (business_type == :university || business_type == :school) ? ".edu" : ".com"

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..365).days : nil

    user.companies.create!(
      parent_company: parent_company,
      name: name,
      description: description,
      status: status || Company.statuses.keys.sample,
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
