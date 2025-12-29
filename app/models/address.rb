# app/models/address.rb
class Address < ApplicationRecord
  include ImmutableRecordConcern

  has_many :address_appointments, dependent: :destroy
  has_many :users, through: :address_appointments, source: :appoint_to, source_type: "User"

  # 1. Validations
  validates :line_1, :city, :country_code, presence: true
  validates :country_code, length: { is: 2 }

  # Ensure the fingerprint is unique
  validates :fingerprint, uniqueness: true

  # 2. Callbacks
  # Calculate fingerprint before checking validation or saving
  before_validation :generate_fingerprint

  enum :country_code, COUNTRIE_CODES, prefix: true

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
