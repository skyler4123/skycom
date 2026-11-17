# frozen_string_literal: true

# PriceListItem — Atomic purpose: one price for one product or service inside a price book, for a minimum quantity.
#
# Why it exists: volume tiers and per-item overrides are the actual content of a price book; storing them as rows lets a wholesaler price 1-9 at one rate and 10+ at another without a new column per break.
# How it works: exactly one of product/service is set. The lookup is (price book, resource, quantity >= min_quantity), highest min_quantity first. Price snapshots still land on the order line, so changing a price list never rewrites an issued quote.
# Main associations: belongs_to :company, :price_list, :product (optional), :service (optional).
class PriceListItem < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :price_list
  belongs_to :product, optional: true
  belongs_to :service, optional: true

  # --- Scopes ---
  scope :tiered, -> { order(min_quantity: :desc) }

  # --- Validations ---
  validates :min_quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :exactly_one_resource

  private

  def exactly_one_resource
    return if product_id.present? ^ service_id.present?

    errors.add(:base, "must reference exactly one product or service")
  end
end
