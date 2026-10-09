class Companies::AttendanceRequestsPolicy < ApplicationPolicy
  def index?; record.can?(:read, AttendanceRequest) end
  def show?; record.can?(:read, AttendanceRequest) end
  def new?; record.can?(:create, AttendanceRequest) end
  def create?; record.can?(:create, AttendanceRequest) end
  def approve?; record.can?(:update, AttendanceRequest) end
  def reject?; record.can?(:update, AttendanceRequest) end
end
