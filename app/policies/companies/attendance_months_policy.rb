class Companies::AttendanceMonthsPolicy < ApplicationPolicy
  def index?; record.can?(:read, AttendanceMonth) end
  def show?;  record.can?(:read, AttendanceMonth) end
end
