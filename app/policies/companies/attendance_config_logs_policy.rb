class Companies::AttendanceConfigLogsPolicy < ApplicationPolicy
  def index?; record.can?(:read, AttendanceConfigLog) end
  def show?; record.can?(:read, AttendanceConfigLog) end
end
