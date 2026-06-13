class Companies::BrandsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Brand)
  end

  def show?
    record.can?(:read, Brand)
  end

  def new?
    record.can?(:create, Brand)
  end

  def create?
    record.can?(:create, Brand)
  end

  def edit?
    record.can?(:update, Brand)
  end

  def update?
    record.can?(:update, Brand)
  end
end
