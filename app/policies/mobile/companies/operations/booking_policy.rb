# frozen_string_literal: true

# Booking runs inside an Operation, so operators only need Operation read.
class Mobile::Companies::Operations::BookingPolicy < ApplicationPolicy
  def show?
    record.can?(:read, Operation)
  end
end
