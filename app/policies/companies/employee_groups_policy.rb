# app/policies/companies/employee_groups_policy.rb
class Companies::EmployeeGroupsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, EmployeeGroup)
  end

  def show?
    record.can?(:read, EmployeeGroup)
  end

  def new?
    record.can?(:create, EmployeeGroup)
  end

  def create?
    record.can?(:create, EmployeeGroup)
  end

  def edit?
    record.can?(:update, EmployeeGroup)
  end

  def update?
    record.can?(:update, EmployeeGroup)
  end
end
