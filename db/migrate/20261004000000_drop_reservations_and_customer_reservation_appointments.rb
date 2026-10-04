class DropReservationsAndCustomerReservationAppointments < ActiveRecord::Migration[8.0]
  def change
    drop_table :customer_reservation_appointments, if_exists: true do |t|
    end
    drop_table :reservations, if_exists: true do |t|
    end
  end
end
