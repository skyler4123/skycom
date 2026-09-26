module OrderConcern
  extend ActiveSupport::Concern

  # Atomic pairwise appointments replaced the polymorphic OrderAppointment.
  # Each includer now declares its own concrete association:
  # - Product => has_many :order_product_appointments
  # - Service => has_many :order_service_appointments
  # - ProductGroup => has_many :order_product_group_appointments
  # - ServiceGroup => has_many :order_service_group_appointments
  # Kept as a no-op so existing `include OrderConcern` lines keep working.
end
