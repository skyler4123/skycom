class Companies::EmployeeSubprofilesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, EmployeeSubprofile)
  end

  def show?
    record.can?(:read, EmployeeSubprofile)
  end

  def new?
    record.can?(:create, EmployeeSubprofile)
  end

  def create?
    record.can?(:create, EmployeeSubprofile)
  end

  def edit?
    record.can?(:update, EmployeeSubprofile)
  end

  def update?
    record.can?(:update, EmployeeSubprofile)
  end

  def destroy?
    record.can?(:delete, EmployeeSubprofile)
  end
end
