# Authorizes the bookable staff roster.
#
# ABAC: every check resolves through the current employee's role/policy set for
# CalendarPractitioner. Owner role bypasses (Employee#owner_role?).
# @see docs/CALENDAR.md
class Companies::CalendarPractitionersPolicy < ApplicationPolicy
  def index?;   record.can?(:read,   CalendarPractitioner) end
  def show?;    record.can?(:read,   CalendarPractitioner) end
  def new?;     record.can?(:create, CalendarPractitioner) end
  def create?;  record.can?(:create, CalendarPractitioner) end
  def edit?;    record.can?(:update, CalendarPractitioner) end
  def update?;  record.can?(:update, CalendarPractitioner) end
  def destroy?; record.can?(:delete, CalendarPractitioner) end
end
