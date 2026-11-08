# app/policies/companies/dashboards_policy.rb
class Companies::DashboardsPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  # The dashboard layout is company-wide configuration — owner-only, mirroring
  # Companies::CompanySettingsPolicy#update?.
  def update?
    record.owner_role?
  end
end
