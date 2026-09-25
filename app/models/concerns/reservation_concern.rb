# app/models/concerns/reservation_concern.rb
module ReservationConcern
  extend ActiveSupport::Concern

  included do
    # Link to the atomic join table
    has_many :customer_reservation_appointments, foreign_key: :customer_id, dependent: :destroy

    # All reservations ever associated with this entity
    has_many :reservations, through: :customer_reservation_appointments, source: :reservation

    # Current active appointments across all types
    has_many :current_customer_reservation_appointments, -> {
               where(lifecycle_status: :active)
             },
             foreign_key: :customer_id,
             class_name: "CustomerReservationAppointment"

    # Quick access to the most recently created active reservation
    has_one :latest_customer_reservation_appointment, -> {
              where(lifecycle_status: :active)
              .order(created_at: :desc)
            },
            foreign_key: :customer_id,
            class_name: "CustomerReservationAppointment"

    has_one :db_reservation, through: :latest_customer_reservation_appointment, source: :reservation
  end

  # Getter: Returns the most recent active Reservation
  def reservation
    cache_key = "#{cache_key_with_version}/current_reservation"
    Rails.cache.fetch(cache_key) { db_reservation }
  end

  # Setter: Primary entry point for attaching a reservation
  def reservation=(code)
    return if code.blank?
    attach_reservation(code)
  end

  def attach_reservation(code, business_type: :primary, **options)
    target_res = Reservation.find_by!(code: code)

    transaction do
      # 1. Archive ONLY the old reservation of the SAME business_type
      # Allows concurrent reservations (e.g., Table Booking AND Spa Service)
      customer_reservation_appointments.where(business_type: business_type)
                                       .where(lifecycle_status: :active)
                                       .update_all(lifecycle_status: CustomerReservationAppointment.lifecycle_statuses[:archived])

      # 2. Create the new appointment
      customer_reservation_appointments.create!(
        reservation: target_res,
        business_type: business_type,
        lifecycle_status: :active,
        workflow_status: options[:workflow_status] || :draft
      )

      # 3. Cache Invalidation
      touch if persisted?
    end
  end

  # Helper to retrieve a reservation for a specific business niche
  def reservation_of_type(type)
    cache_key = "#{cache_key_with_version}/reservation_#{type}"
    Rails.cache.fetch(cache_key) do
      customer_reservation_appointments.where(lifecycle_status: :active, business_type: type)
                                       .first&.reservation
    end
  end
end



# customer = Customer.find(id)

# # 1. A Restaurant Branch creates a table booking
# customer.attach_reservation("RES-TABLE-101", business_type: :dining)

# # 2. A Service Department creates a technician visit (Does not archive the dining reservation!)
# customer.attach_reservation("RES-HVAC-99", business_type: :maintenance)

# # 3. Retrieve specific context
# customer.reservation_of_type(:dining)      # => <Reservation: Table 101>
# customer.reservation_of_type(:maintenance) # => <Reservation: HVAC Repair>

# # 4. Global view
# customer.reservation # => <Reservation: HVAC Repair> (The latest one)
