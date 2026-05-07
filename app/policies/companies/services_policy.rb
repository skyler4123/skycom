# app/policies/companies/services_policy.rb
class Companies::ServicesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Service)
  end

  def create?
    record.can?(:create, Service)
  end

  def update?
    record.can?(:update, Service)
  end
end
