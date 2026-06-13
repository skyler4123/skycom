class Companies::ServicesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Service)
  end

  def show?
    record.can?(:read, Service)
  end

  def new?
    record.can?(:create, Service)
  end

  def create?
    record.can?(:create, Service)
  end

  def edit?
    record.can?(:update, Service)
  end

  def update?
    record.can?(:update, Service)
  end
end
