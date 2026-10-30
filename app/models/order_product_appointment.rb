# frozen_string_literal: true

# OrderProductAppointment — Atomic purpose: order line binding one Order to one
# Product, carrying the quantity/unit_price/total_price snapshot.
#
# Why it exists: captures the price snapshot at time of order, so later catalog
# price changes never rewrite history.
# How it works: created in bulk by OrderProcessingV1::CreateOrderService via
# insert_all!; read via `order.order_product_appointments`. Never edit snapshots
# after payment. company_id derives from the order via SetDefaultCompanyConcern.
# Main associations: belongs_to :company, :order, :product (required); :stock
# (optional — exact row reserved at POS pay time).
class OrderProductAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :order
  belongs_to :product
  belongs_to :stock, optional: true # exact row reserved at POS pay time (warehouse-deterministic finalize)
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :unit_price, :total_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
