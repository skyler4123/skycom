# frozen_string_literal: true

# CartGroup — Atomic purpose: company-scoped grouping of carts (abandoned,
# active carts, wishlists).
#
# Why it exists: separates cart groupings from individual carts and carries its
# own category/property schema.
# How it works: belongs to company/branch/category/property mapping; carts
# reference the group with belongs_to :cart_group.
# Main associations: belongs_to :company, :category, :property_mapping
# (required), :branch (optional).
class CartGroup < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    abandoned: 0,
    active_carts: 1,
    wishlists: 2
  }
  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping
  # has_many :cart_group_appointments, dependent: :destroy # This can be added later

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :branch_id }

  validates :business_type, presence: true
end
