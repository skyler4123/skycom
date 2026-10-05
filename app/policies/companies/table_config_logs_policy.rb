class Companies::TableConfigLogsPolicy < ApplicationPolicy
  def index?; record.can?(:read, TableConfigLog) end
  def show?; record.can?(:read, TableConfigLog) end
end
