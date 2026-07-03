class Companies::AttendancesPolicy < ApplicationPolicy
  def index?; record.can?(:read, AttendanceRecord) end
  def show?;  record.can?(:read, AttendanceRecord) end
end
