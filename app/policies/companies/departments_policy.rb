# app/policies/companies/departments_policy.rb
class Companies::DepartmentsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Department)
  end

  def create?
    record.can?(:create, Department)
  end

  def update?
    record.can?(:update, Department)
  end
end
