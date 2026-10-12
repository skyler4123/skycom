# app/policies/companies/notification_tags_policy.rb
class Companies::NotificationTagsPolicy < ApplicationPolicy
  def index?;   record.can?(:read,   NotificationTag) end
  def show?;    record.can?(:read,   NotificationTag) end
  def new?;     record.can?(:create, NotificationTag) end
  def create?;  record.can?(:create, NotificationTag) end
  def edit?;    record.can?(:update, NotificationTag) end
  def update?;  record.can?(:update, NotificationTag) end
  def destroy?; record.can?(:delete, NotificationTag) end
end
