# app/policies/companies/company_settings_policy.rb
class Companies::CompanySettingsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, CompanySetting)
  end

  def update?
    record.can?(:update, CompanySetting)
  end
end
