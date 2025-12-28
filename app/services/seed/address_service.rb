class Seed::AddressService
  def self.create(
    line_1: Faker::Address.street_address,
    line_2: Faker::Address.secondary_address,
    city: Faker::Address.city,
    state_or_province: Faker::Address.state,
    postal_code: Faker::Address.postcode,
    country_code: Faker::Address.country_code
  )
    # The Address model is expected to handle fingerprint generation (e.g., before_validation)
    Address.reusable_create(
      line_1: line_1,
      line_2: line_2,
      city: city,
      state_or_province: state_or_province,
      postal_code: postal_code,
      country_code: country_code.to_s.first(2).upcase
    )
  end
end
