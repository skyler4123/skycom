# app/policies/companies/products_policy.rb
class Companies::ProductsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Product)
  end

  def create?
    record.can?(:create, Product)
  end

  def update?
    record.can?(:update, Product)
  end
end
