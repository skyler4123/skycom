# frozen_string_literal: true

# ProductGroup — Atomic purpose: company-scoped grouping of products (category,
# collection, line) used for merchandising and order lines.
#
# Why it exists: groups related products for browsing and pricing, and lets an
# order reference a group line without expanding every product; it carries its
# own category/property schema.
# How it works: belongs to company/branch (optional) and required category/
# property mapping; products join through ProductProductGroupAppointment, and
# orders can reference group lines through OrderProductGroupAppointment.
# Main associations: belongs_to :company, :category, :property_mapping
# (required), :branch (optional); has_many :products through
# :product_product_group_appointments; has_many :orders through
# :order_product_group_appointments (both dependent: :destroy).
class ProductGroup < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern

  include TagConcern
  include OrderConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    category: 0,
    collection: 1,
    line: 2
  }
  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping
  has_many :product_product_group_appointments, dependent: :destroy
  has_many :products, through: :product_product_group_appointments
  has_many :order_product_group_appointments, dependent: :destroy
  has_many :orders, through: :order_product_group_appointments

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :branch_id }

  validates :business_type, presence: true
end
