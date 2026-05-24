class Companies::BrandsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Brand)
  end

  def create?
    record.can?(:create, Brand)
  end

  def update?
    record.can?(:update, Brand)
  end
end
