class Companies::FacilitiesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Facility)
  end

  def create?
    record.can?(:create, Facility)
  end

  def update?
    record.can?(:update, Facility)
  end
end
