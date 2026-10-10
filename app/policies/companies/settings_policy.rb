# app/policies/companies/settings_policy.rb
class Companies::SettingsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Setting)
  end

  def update?
    record.can?(:update, Setting)
  end

  # Personal sidebar is self-service: any signed-in employee manages only
  # their own record (controller scopes to current_employee). No Setting
  # grant required.
  def personal?
    true
  end

  def update_personal?
    true
  end
end
