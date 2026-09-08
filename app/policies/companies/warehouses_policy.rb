class Companies::WarehousesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Warehouse)
  end

  def show?
    record.can?(:read, Warehouse)
  end

  def new?
    record.can?(:create, Warehouse)
  end

  def create?
    record.can?(:create, Warehouse)
  end

  def edit?
    record.can?(:update, Warehouse)
  end

  def update?
    record.can?(:update, Warehouse)
  end
end
