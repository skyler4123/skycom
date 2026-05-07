# app/policies/companies/customers_policy.rb
class Companies::CustomersPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Customer)
  end

  def create?
    record.can?(:create, Customer)
  end

  def update?
    record.can?(:update, Customer)
  end
end
