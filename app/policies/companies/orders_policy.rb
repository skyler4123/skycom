# app/policies/companies/orders_policy.rb
class Companies::OrdersPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Order)
  end

  def show?
    record.can?(:read, Order)
  end

  def new?
    record.can?(:create, Order)
  end

  def create?
    record.can?(:create, Order)
  end

  def edit?
    record.can?(:update, Order)
  end

  def update?
    record.can?(:update, Order)
  end
end
