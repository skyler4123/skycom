# Authorizes bookable rooms / places.
#
# ABAC: every check resolves through the current employee's role/policy set for
# CalendarLocation. Owner role bypasses (Employee#owner_role?).
# @see docs/CALENDAR.md
class Companies::CalendarLocationsPolicy < ApplicationPolicy
  def index?;   record.can?(:read,   CalendarLocation) end
  def show?;    record.can?(:read,   CalendarLocation) end
  def new?;     record.can?(:create, CalendarLocation) end
  def create?;  record.can?(:create, CalendarLocation) end
  def edit?;    record.can?(:update, CalendarLocation) end
  def update?;  record.can?(:update, CalendarLocation) end
  def destroy?; record.can?(:delete, CalendarLocation) end
end
