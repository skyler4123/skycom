# frozen_string_literal: true

class Companies::Operations::BookingPolicy < Companies::Operations::BasePolicy
  # Booking operators create and manage reservations from the console; every
  # write and lookup shares the show gate.
  def create_reservation? = show?
  def customers? = show?
  def extend_reservation? = show?
  def finish_reservation? = show?
  def cancel_reservation? = show?
end
