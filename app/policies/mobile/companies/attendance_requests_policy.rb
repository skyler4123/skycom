# frozen_string_literal: true

class Mobile::Companies::AttendanceRequestsPolicy < ApplicationPolicy
  def new?
    record.can?(:create, AttendanceRequest)
  end

  def create?
    record.can?(:create, AttendanceRequest)
  end
end
