# frozen_string_literal: true

# Self-service: Mobile::Companies::BaseController resolves @employee from
# current_user + company_id, so this screen can only show the signed-in
# employee's own profile. Company membership is the authorization boundary.
class Mobile::Companies::EmployeesPolicy < ApplicationPolicy
  def show?
    true
  end
end
