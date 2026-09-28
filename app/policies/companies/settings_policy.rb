# app/policies/companies/settings_policy.rb
class Companies::SettingsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Setting)
  end
end
