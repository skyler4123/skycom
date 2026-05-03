# app/models/concerns/reservation_concern.rb
module ReservationConcern
  extend ActiveSupport::Concern

  included do
    # Link to the appointment join table as the recipient/target
    has_many :reservation_appointments, as: :appoint_to, dependent: :destroy

    # All reservations ever associated with this entity
    has_many :reservations, through: :reservation_appointments, source: :reservation

    # Current active appointments across all types
    has_many :current_reservation_appointments, -> {
               where(lifecycle_status: :active)
             },
             as: :appoint_to,
             class_name: "ReservationAppointment"

    # Quick access to the most recently created active reservation
    has_one :latest_reservation_appointment, -> {
              where(lifecycle_status: :active)
              .order(created_at: :desc)
            },
            as: :appoint_to,
            class_name: "ReservationAppointment"

    has_one :db_reservation, through: :latest_reservation_appointment, source: :reservation
  end

  # Getter: Returns the most recent active Reservation
  def reservation
    cache_key = "#{cache_key_with_version}/current_reservation"
    Rails.cache.fetch(cache_key) { db_reservation }
  end

  # Setter: Primary entry point for attaching a reservation via code
  def reservation=(code)
    return if code.blank?
    attach_reservation(code)
  end

  def attach_reservation(code, business_type: :primary, **options)
    target_res = Reservation.find_by!(code: code)

    self.transaction do
      # 1. Archive ONLY the old reservation of the SAME business_type
      # Allows concurrent reservations (e.g., Table Booking AND Spa Service)
      reservation_appointments.where(business_type: business_type)
                             .where(lifecycle_status: :active)
                             .update_all(lifecycle_status: :archived)

      # 2. Create the new appointment using polymorphic DNA
      reservation_appointments.create!(
        reservation:      target_res,
        business_type:    business_type,
        appoint_from:     options[:from],
        appoint_for:      options[:for],
        appoint_by:       options[:by],
        lifecycle_status: :active,
        workflow_status:  options[:workflow_status] || :pending
      )

      # 3. Cache Invalidation
      self.touch if self.persisted?
    end
  end

  # Helper to retrieve a reservation for a specific business niche
  def reservation_of_type(type)
    cache_key = "#{cache_key_with_version}/reservation_#{type}"
    Rails.cache.fetch(cache_key) do
      reservation_appointments.where(lifecycle_status: :active, business_type: type)
                             .first&.reservation
    end
  end
end




# customer = Customer.find(id)

# # 1. A Restaurant Branch creates a table booking
# customer.attach_reservation("RES-TABLE-101", business_type: :dining, from: branch_office)

# # 2. A Service Department creates a technician visit (Does not archive the dining reservation!)
# customer.attach_reservation("RES-HVAC-99", business_type: :maintenance, from: tech_dept)

# # 3. Retrieve specific context
# customer.reservation_of_type(:dining)      # => <Reservation: Table 101>
# customer.reservation_of_type(:maintenance) # => <Reservation: HVAC Repair>

# # 4. Global view
# customer.reservation # => <Reservation: HVAC Repair> (The latest one)
