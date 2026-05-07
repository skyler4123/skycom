# app/policies/companies/policies_controller_policy.rb
class Companies::PoliciesControllerPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Policy)
  end
end
