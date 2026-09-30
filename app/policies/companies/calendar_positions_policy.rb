# Authorizes bookable job positions.
#
# ABAC: every check resolves through the current employee's role/policy set for
# CalendarPosition. Owner role bypasses (Employee#owner_role?).
# @see docs/CALENDAR.md
class Companies::CalendarPositionsPolicy < ApplicationPolicy
  def index?;   record.can?(:read,   CalendarPosition) end
  def show?;    record.can?(:read,   CalendarPosition) end
  def new?;     record.can?(:create, CalendarPosition) end
  def create?;  record.can?(:create, CalendarPosition) end
  def edit?;    record.can?(:update, CalendarPosition) end
  def update?;  record.can?(:update, CalendarPosition) end
  def destroy?; record.can?(:delete, CalendarPosition) end
end
