# app/policies/companies/dashboards_controller_policy.rb
class Companies::DashboardsControllerPolicy < ApplicationPolicy
  def index?
    true
  end
end
