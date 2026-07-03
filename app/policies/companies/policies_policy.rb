# app/policies/companies/policies_policy.rb
class Companies::PoliciesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Policy)
  end
end
