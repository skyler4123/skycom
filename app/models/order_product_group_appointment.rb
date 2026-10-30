# frozen_string_literal: true

# OrderProductGroupAppointment — Atomic purpose: atomic row binding an Order to
# one ProductGroup.
#
# Why it exists: captures the price snapshot (quantity/unit_price/total_price)
# at time of order, so later catalog price changes never rewrite history.
#
# How to use: created in bulk by OrderProcessingV1::CreateOrderService via
# insert_all!; read via the matching has_many on Order (e.g.
# order_product_appointments). Never edit snapshots after payment.
#
# How it works: concrete FKs to company/order/chargeable; company_id derives
# from the order via SetDefaultCompanyConcern.
#
# Main associations: belongs_to :company, :order, :product_group, :stock
# (optional).
class OrderProductGroupAppointment < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :order
  belongs_to :product_group
  belongs_to :stock, optional: true # exact row reserved at POS pay time (warehouse-deterministic finalize)
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :unit_price, :total_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
