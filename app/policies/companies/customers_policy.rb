# app/policies/companies/customers_policy.rb
class Companies::CustomersPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Customer)
  end

  def show?
    record.can?(:read, Customer)
  end

  def new?
    record.can?(:create, Customer)
  end

  def create?
    record.can?(:create, Customer)
  end

  def edit?
    record.can?(:update, Customer)
  end

  def update?
    record.can?(:update, Customer)
  end
end
