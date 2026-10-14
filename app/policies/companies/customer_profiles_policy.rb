class Companies::CustomerProfilesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, CustomerProfile)
  end

  def show?
    record.can?(:read, CustomerProfile)
  end

  def new?
    record.can?(:create, CustomerProfile)
  end

  def create?
    record.can?(:create, CustomerProfile)
  end

  def edit?
    record.can?(:update, CustomerProfile)
  end

  def update?
    record.can?(:update, CustomerProfile)
  end

  def destroy?
    record.can?(:delete, CustomerProfile)
  end
end
