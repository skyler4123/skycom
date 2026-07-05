class Companies::AttendanceLogsPolicy < ApplicationPolicy
  def index?; record.can?(:read, AttendanceLog) end
  def show?;  record.can?(:read, AttendanceLog) end
end
