class Companies::AttendanceConfigsPolicy < ApplicationPolicy
  def index?;  record.can?(:read,   AttendanceConfig) end
  def show?;   record.can?(:read,   AttendanceConfig) end
  def new?;    record.can?(:create, AttendanceConfig) end
  def create?; record.can?(:create, AttendanceConfig) end
  def edit?;   record.can?(:update, AttendanceConfig) end
  def update?; record.can?(:update, AttendanceConfig) end
end
