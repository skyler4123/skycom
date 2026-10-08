class Companies::PermissionLogsPolicy < ApplicationPolicy
  def index?; record.can?(:read, PermissionLog) end
  def show?; record.can?(:read, PermissionLog) end
end
