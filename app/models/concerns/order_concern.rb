# == Purpose:
# Marker for chargeable resources (Product, Service, ProductGroup,
# ServiceGroup, SubscriptionPlan) that can appear as Order line items.
#
# == How It Works:
# The old polymorphic OrderAppointment is gone: each chargeable now declares
# its own concrete association on itself AND on Order (e.g.
# OrderProductAppointment, readable via order.order_product_appointments).
# This concern is intentionally a no-op so existing `include OrderConcern`
# lines keep working without implying shared behavior.
#
# == Usage:
# Include in any chargeable model. Create rows through
# OrderProcessingV1::CreateOrderService (bulk insert_all! with price
# snapshots), never by hand-editing snapshots after payment.
#
# == Example:
#   class Product < ApplicationRecord
#     include OrderConcern
#     has_many :order_product_appointments, dependent: :destroy
#     has_many :orders, through: :order_product_appointments
#   end
module OrderConcern
  extend ActiveSupport::Concern
end
