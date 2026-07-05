class Companies::AttendanceDaysPolicy < ApplicationPolicy
  def index?; record.can?(:read, AttendanceDay) end
  def show?;  record.can?(:read, AttendanceDay) end
end
