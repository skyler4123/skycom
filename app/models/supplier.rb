# frozen_string_literal: true

# Supplier — Atomic purpose: company-scoped vendor that supplies products or
# services and is referenced by purchases.
#
# Why it exists: purchases need a reusable counterparty with contact, category,
# and dynamic properties; tags keep suppliers in the ABAC vocabulary.
# How it works: belongs to company/category/property mapping; purchases reference
# the supplier; tags and dynamic search come from concerns.
# Main associations: belongs_to :company, :category, :property_mapping
# (required).
class Supplier < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  # Defines the supply category of the supplier.
  enum :business_type, {
    manufacturer: 0,
    distributor: 1,
    wholesaler: 2,
    service_provider: 3
  }

  # --- Associations ---
  belongs_to :company
  belongs_to :category
  belongs_to :property_mapping

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :description, length: { maximum: 5000 }, allow_blank: true

  validates :business_type, presence: true
end
