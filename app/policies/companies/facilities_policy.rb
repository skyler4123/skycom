class Companies::FacilitiesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Facility)
  end

  def show?
    record.can?(:read, Facility)
  end

  def new?
    record.can?(:create, Facility)
  end

  def create?
    record.can?(:create, Facility)
  end

  def edit?
    record.can?(:update, Facility)
  end

  def update?
    record.can?(:update, Facility)
  end
end
