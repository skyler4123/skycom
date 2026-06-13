# app/policies/companies/products_policy.rb
class Companies::ProductsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Product)
  end

  def show?
    record.can?(:read, Product)
  end

  def new?
    record.can?(:create, Product)
  end

  def create?
    record.can?(:create, Product)
  end

  def edit?
    record.can?(:update, Product)
  end

  def update?
    record.can?(:update, Product)
  end
end
