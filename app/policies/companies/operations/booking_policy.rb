# frozen_string_literal: true

class Companies::Operations::BookingPolicy < Companies::Operations::BasePolicy
  # Booking operators create reservations from the console; the write shares
  # the show gate.
  def create_reservation?
    show?
  end
end
