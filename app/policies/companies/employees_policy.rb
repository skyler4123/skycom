class Companies::EmployeesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Employee)
  end

  def show?
    record.can?(:read, Employee)
  end

  def new?
    record.can?(:create, Employee)
  end

  def create?
    record.can?(:create, Employee)
  end

  def edit?
    record.can?(:update, Employee)
  end

  def update?
    record.can?(:update, Employee)
  end

  def destroy?
    record.can?(:delete, Employee)
  end
end
