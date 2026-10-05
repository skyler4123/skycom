class Companies::EventConfigLogsPolicy < ApplicationPolicy
  def index?; record.can?(:read, EventConfigLog) end
  def show?; record.can?(:read, EventConfigLog) end
end
