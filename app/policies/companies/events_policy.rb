class Companies::EventsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Event)
  end

  def show?
    record.can?(:read, Event)
  end

  def new?
    record.can?(:create, Event)
  end

  def create?
    record.can?(:create, Event)
  end

  def edit?
    record.can?(:update, Event)
  end

  def update?
    record.can?(:update, Event)
  end
end
