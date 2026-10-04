class Companies::EventConfigsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, EventConfig)
  end

  def show?
    record.can?(:read, EventConfig)
  end

  def new?
    record.can?(:create, EventConfig)
  end

  def create?
    record.can?(:create, EventConfig)
  end

  def edit?
    record.can?(:update, EventConfig)
  end

  def update?
    record.can?(:update, EventConfig)
  end
end
