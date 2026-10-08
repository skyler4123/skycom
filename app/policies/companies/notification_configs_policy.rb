# app/policies/companies/notification_configs_policy.rb
class Companies::NotificationConfigsPolicy < ApplicationPolicy
  def show?;   record.can?(:read,   Notification) end
  def update?; record.can?(:update, Notification) end
end
