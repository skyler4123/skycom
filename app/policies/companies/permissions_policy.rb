# app/policies/companies/permissions_policy.rb
class Companies::PermissionsPolicy < ApplicationPolicy
  def index?
    # 'record' is the current_employee passed from the controller
    record.can?(:read, PolicyAppointment)
  end

  def create?
    record.can?(:create, PolicyAppointment)
  end

  def update?
    # For instance-level checks (tags), you'd pass the actual object
    # but for general creation/index, checking the employee works perfectly.
    record.can?(:update, PolicyAppointment)
  end
end
