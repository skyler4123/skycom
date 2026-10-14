class Companies::CustomerSubprofilesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, CustomerSubprofile)
  end

  def show?
    record.can?(:read, CustomerSubprofile)
  end

  def new?
    record.can?(:create, CustomerSubprofile)
  end

  def create?
    record.can?(:create, CustomerSubprofile)
  end

  def edit?
    record.can?(:update, CustomerSubprofile)
  end

  def update?
    record.can?(:update, CustomerSubprofile)
  end
end
