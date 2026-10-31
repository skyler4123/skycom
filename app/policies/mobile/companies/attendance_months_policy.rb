# frozen_string_literal: true

# Self-service: the controller reads @employee from current_user + company_id,
# so only the signed-in employee's own attendance month is reachable.
class Mobile::Companies::AttendanceMonthsPolicy < ApplicationPolicy
  def show?
    true
  end
end
