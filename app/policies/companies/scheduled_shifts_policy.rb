class Companies::ScheduledShiftsPolicy < ApplicationPolicy
  def index?;  record.can?(:read,   ScheduledShift) end
  def show?;   record.can?(:read,   ScheduledShift) end
  def new?;    record.can?(:create, ScheduledShift) end
  def create?; record.can?(:create, ScheduledShift) end
  def edit?;   record.can?(:update, ScheduledShift) end
  def update?; record.can?(:update, ScheduledShift) end
end
