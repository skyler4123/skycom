# Authorizes the people appointments are booked for.
#
# ABAC: every check resolves through the current employee's role/policy set for
# CalendarParticipant. Owner role bypasses (Employee#owner_role?).
# @see docs/CALENDAR.md
class Companies::CalendarParticipantsPolicy < ApplicationPolicy
  def index?;   record.can?(:read,   CalendarParticipant) end
  def show?;    record.can?(:read,   CalendarParticipant) end
  def new?;     record.can?(:create, CalendarParticipant) end
  def create?;  record.can?(:create, CalendarParticipant) end
  def edit?;    record.can?(:update, CalendarParticipant) end
  def update?;  record.can?(:update, CalendarParticipant) end
  def destroy?; record.can?(:delete, CalendarParticipant) end
end
