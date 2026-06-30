class Seed::AddressService
  def self.create(country_code: nil)
    {
      line_1: Faker::Address.street_address,
      line_2: Faker::Address.secondary_address,
      city: Faker::Address.city,
      state_or_province: Faker::Address.state,
      postal_code: Faker::Address.postcode,
      country_code: country_code || Address.country_codes.keys.sample,
      business_type: :office # Default type for seeds
    }
  end
end
