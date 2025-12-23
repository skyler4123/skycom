# app/models/address.rb
class Address < ApplicationRecord
  # 1. Validations
  validates :line_1, :city, :country_code, presence: true
  validates :country_code, length: { is: 2 }
  
  # Ensure the fingerprint is unique
  validates :fingerprint, uniqueness: true

  # 2. Callbacks
  # Calculate fingerprint before checking validation or saving
  before_validation :generate_fingerprint

  # 3. Reusable Logic
  def self.reusable_create(line_1:, city:, country_code:, line_2: nil, state: nil, zip: nil)
    # create a temporary instance to calculate the hash
    temp = new(
      line_1: line_1, 
      line_2: line_2, 
      city: city, 
      state_or_province: state, 
      postal_code: zip, 
      country_code: country_code
    )
    temp.generate_fingerprint

    # Find existing by fingerprint, or create the new one
    find_or_create_by(fingerprint: temp.fingerprint) do |addr|
      # If creating new, set the attributes
      addr.line_1 = line_1
      addr.line_2 = line_2
      addr.city = city
      addr.state_or_province = state
      addr.postal_code = zip
      addr.country_code = country_code
    end
  end

  # 4. Fingerprint Generator
  # Normalizes text (downcase, strip) and hashes it
  def generate_fingerprint
    # Combine relevant fields, handling nils safely
    # Example raw string: "123 main st|apt 4|new york|ny|10001|us"
    components = [
      line_1, 
      line_2, 
      city, 
      state_or_province, 
      postal_code, 
      country_code
    ].map { |val| val.to_s.strip.downcase }

    raw_string = components.join("|")
    
    # Create SHA256 Hash
    self.fingerprint = Digest::SHA256.hexdigest(raw_string)
  end
end


# # User creates an order with an address
# addr = Address.reusable_address(
#   line_1: "123 Le Loi",
#   city: "District 1",
#   state: "Ho Chi Minh City",
#   country_code: "VN"
# )

# # addr is now a saved Address record. 
# # If you run this exact code again, it returns the EXISTING record.