class Companies::SuppliersPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Supplier)
  end

  def show?
    record.can?(:read, Supplier)
  end

  def new?
    record.can?(:create, Supplier)
  end

  def create?
    record.can?(:create, Supplier)
  end

  def edit?
    record.can?(:update, Supplier)
  end

  def update?
    record.can?(:update, Supplier)
  end
end
