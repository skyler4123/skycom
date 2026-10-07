# app/policies/companies/notifications_policy.rb
class Companies::NotificationsPolicy < ApplicationPolicy
  def index?;          record.can?(:read,   Notification) end
  def show?;           record.can?(:read,   Notification) end
  def mark_read?;      record.can?(:read,   Notification) end
  def mark_all_read?;  record.can?(:read,   Notification) end
  def unread_count?;   record.can?(:read,   Notification) end
end
