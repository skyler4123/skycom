# Authorizes the Calendar/Schedule board (the month/week/day grid).
#
# The board only ever reads bookings, so it resolves against CalendarEvent read
# permission rather than owning a resource of its own. Owns owner role bypasses
# (Employee#owner_role?).
# @see docs/CALENDAR.md
class Companies::CalendarsPolicy < ApplicationPolicy
  def index?; record.can?(:read, CalendarEvent) end
  def show?;  record.can?(:read, CalendarEvent) end
  # GET /calendars/events — the grid's range query.
  def events?; record.can?(:read, CalendarEvent) end
end
