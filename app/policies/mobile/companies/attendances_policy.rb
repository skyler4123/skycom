# frozen_string_literal: true

class Mobile::Companies::AttendancesPolicy < ApplicationPolicy
  def create?
    record.can?(:read, Notification)
  end
end
