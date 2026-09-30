# Authorizes the booking list, the booking form and the status transitions (confirm / cancel / complete).
#
# ABAC: every check resolves through the current employee's role/policy set for
# CalendarEvent. Owner role bypasses (Employee#owner_role?).
# @see docs/CALENDAR.md
class Companies::CalendarEventsPolicy < ApplicationPolicy
  def index?;   record.can?(:read,   CalendarEvent) end
  def show?;    record.can?(:read,   CalendarEvent) end
  def new?;     record.can?(:create, CalendarEvent) end
  def create?;  record.can?(:create, CalendarEvent) end
  def edit?;    record.can?(:update, CalendarEvent) end
  def update?;  record.can?(:update, CalendarEvent) end
  def destroy?; record.can?(:delete, CalendarEvent) end

  # Read-only pre-flight for the booking form — a preview, not a write, so it
  # needs only read.
  def conflicts?; record.can?(:read, CalendarEvent) end

  # Status transitions are updates to the booking, not deletions.
  def confirm?;  record.can?(:update, CalendarEvent) end
  def cancel?;   record.can?(:update, CalendarEvent) end
  def complete?; record.can?(:update, CalendarEvent) end
end
