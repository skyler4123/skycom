# frozen_string_literal: true

# PurchaseItem — Atomic purpose: one purchasable item definition used on purchase
# lines, optionally bridged to a Product for stock import.
#
# Why it exists: purchase lines need a catalog row with its own category/property
# schema; when product is set, completing the purchase imports that product into
# the destination warehouse.
# How it works: belongs to company/category/property mapping and optional product;
# purchases reference items through PurchasePurchaseItemAppointment.
# Main associations: belongs_to :company, :category, :property_mapping
# (required), :product (optional); has_many :purchases through
# :purchase_purchase_item_appointments (dependent: :destroy).
class PurchaseItem < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :category
  belongs_to :property_mapping
  # The Purchase ↔ Stock bridge: when set, purchase completion imports this
  # product into the purchase's destination warehouse (StockMovementService::
  # Purchases::CompleteService). Nil for non-stocked purchases.
  belongs_to :product, optional: true

  has_many :purchase_purchase_item_appointments, dependent: :destroy
  has_many :purchases, through: :purchase_purchase_item_appointments

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
end
