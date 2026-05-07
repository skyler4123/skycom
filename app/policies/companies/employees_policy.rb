# app/policies/companies/employees_policy.rb
class Companies::EmployeesPolicy < ApplicationPolicy
  def index?
    # 'record' is the current_employee passed from the controller
    record.can?(:read, Employee)
  end

  def create?
    record.can?(:create, Employee)
  end

  def update?
    # For instance-level checks (tags), you'd pass the actual object
    # but for general creation/index, checking the employee works perfectly.
    record.can?(:update, Employee)
  end

  def destroy?
    record.can?(:delete, Employee)
  end
end
