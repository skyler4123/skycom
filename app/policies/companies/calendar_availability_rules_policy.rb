# Authorizes practitioner / room working hours.
#
# ABAC: every check resolves through the current employee's role/policy set for
# CalendarAvailabilityRule. Owner role bypasses (Employee#owner_role?).
# @see docs/CALENDAR.md
class Companies::CalendarAvailabilityRulesPolicy < ApplicationPolicy
  def index?;   record.can?(:read,   CalendarAvailabilityRule) end
  def show?;    record.can?(:read,   CalendarAvailabilityRule) end
  def new?;     record.can?(:create, CalendarAvailabilityRule) end
  def create?;  record.can?(:create, CalendarAvailabilityRule) end
  def edit?;    record.can?(:update, CalendarAvailabilityRule) end
  def update?;  record.can?(:update, CalendarAvailabilityRule) end
  def destroy?; record.can?(:delete, CalendarAvailabilityRule) end
end
