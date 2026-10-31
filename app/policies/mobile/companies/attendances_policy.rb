# frozen_string_literal: true

# Self-service: the controller always stamps the AttendanceLog with @employee
# resolved from current_user + company_id, so a member can only check in
# themselves.
class Mobile::Companies::AttendancesPolicy < ApplicationPolicy
  def create?
    true
  end
end
