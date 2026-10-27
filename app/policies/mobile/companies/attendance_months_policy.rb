# frozen_string_literal: true

class Mobile::Companies::AttendanceMonthsPolicy < ApplicationPolicy
  def show?
    record.can?(:read, Notification)
  end
end
