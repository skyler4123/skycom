# frozen_string_literal: true

# Address — Atomic purpose: shared, immutable address row deduplicated by a
# SHA256 fingerprint of its normalized fields.
#
# Why it exists: many owners (companies, branches, customers, employees, ...)
# can point at the same address without duplicating data; immutability keeps the
# shared row safe and preserves history (see docs/ADDRESS.md).
# How it works: `before_validation` builds the fingerprint from line_1/line_2/
# city/state_or_province/postal_code/country, and the unique fingerprint makes
# `find_or_create_by!` reuse the existing row. Owners attach through their
# AddressConcern (`record.attach_address(...)`), which archives the previous
# active appointment instead of editing the address.
# Main associations: has_many :<owner>_appointments (dependent: :destroy) and
# has_many :<owners>, through: ... for Branch, Company, Customer, CustomerGroup,
# Department, Employee, EmployeeGroup, and User.
class Address < ApplicationRecord
  include ImmutableRecordConcern

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  has_many :address_branch_appointments, dependent: :destroy
  has_many :branches, through: :address_branch_appointments
  has_many :address_company_appointments, dependent: :destroy
  has_many :companies, through: :address_company_appointments
  has_many :address_customer_appointments, dependent: :destroy
  has_many :customers, through: :address_customer_appointments
  has_many :address_customer_group_appointments, dependent: :destroy
  has_many :customer_groups, through: :address_customer_group_appointments
  has_many :address_department_appointments, dependent: :destroy
  has_many :departments, through: :address_department_appointments
  has_many :address_employee_appointments, dependent: :destroy
  has_many :employees, through: :address_employee_appointments
  has_many :address_employee_group_appointments, dependent: :destroy
  has_many :employee_groups, through: :address_employee_group_appointments
  has_many :address_user_appointments, dependent: :destroy
  has_many :users, through: :address_user_appointments

  # 1. Validations
  validates :line_1, :city, :country, presence: true

  # Ensure the fingerprint is unique
  validates :fingerprint, uniqueness: true

  # 2. Callbacks
  # Calculate fingerprint before checking validation or saving
  before_validation :generate_fingerprint

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
      country
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
