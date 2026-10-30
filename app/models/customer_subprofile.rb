# frozen_string_literal: true

# CustomerSubprofile — Atomic purpose: leaf-level detail row under a
# CustomerProfile, using its own category/property schema.
#
# Why it exists: lets the customer profile hierarchy go one level deeper (e.g.
# per contact or contract) without widening the profile table (see
# docs/PROFILE_SUBPROFILE.md).
# How it works: belongs to a customer, CustomerProfile, company, category, and
# property mapping; validates that customer/company match the parent profile.
# Discard is supported through Discard::Model.
# Main associations: belongs_to :customer_profile, :customer, :company,
# :category, :property_mapping (required), :branch (optional).
class CustomerSubprofile < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  include Discard::Model
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    general: 0,
    special: 1
  }

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :customer
  belongs_to :customer_profile
  belongs_to :category
  belongs_to :property_mapping

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :customer_profile_id }, length: { maximum: 255 }
  validates :code, uniqueness: { scope: :company_id }, allow_blank: true
  validates :description, length: { maximum: 5000 }, allow_blank: true

  validates :business_type, presence: true
  validate :customer_matches_profile_customer

  private

  def customer_matches_profile_customer
    return if customer_id.blank? || customer_profile.nil?

    if customer_id != customer_profile.customer_id
      errors.add(:customer, "must match profile's customer")
    end
    if company_id != customer_profile.company_id
      errors.add(:company, "must match profile's company")
    end
  end
end
