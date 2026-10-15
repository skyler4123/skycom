class Companies::EmployeeProfilesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, EmployeeProfile)
  end

  def show?
    record.can?(:read, EmployeeProfile)
  end

  def new?
    record.can?(:create, EmployeeProfile)
  end

  def create?
    record.can?(:create, EmployeeProfile)
  end

  def edit?
    record.can?(:update, EmployeeProfile)
  end

  def update?
    record.can?(:update, EmployeeProfile)
  end

  def destroy?
    record.can?(:delete, EmployeeProfile)
  end
end
