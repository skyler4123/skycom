# app/policies/companies/dashboards_policy.rb
class Companies::DashboardsPolicy < ApplicationPolicy
  def index?
    true
  end
end
