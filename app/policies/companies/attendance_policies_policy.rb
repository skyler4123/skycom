class Companies::AttendancePoliciesPolicy < ApplicationPolicy
  def index?;  record.can?(:read,   AttendancePolicy) end
  def show?;   record.can?(:read,   AttendancePolicy) end
  def new?;    record.can?(:create, AttendancePolicy) end
  def create?; record.can?(:create, AttendancePolicy) end
  def edit?;   record.can?(:update, AttendancePolicy) end
  def update?; record.can?(:update, AttendancePolicy) end
end
