# app/policies/companies/bookings_policy.rb
class Companies::BookingsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Booking)
  end

  def create?
    record.can?(:create, Booking)
  end

  def update?
    record.can?(:update, Booking)
  end
end
