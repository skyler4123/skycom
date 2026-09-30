# Authorizes the read-only external provider connections page.
#
# ABAC: every check resolves through the current employee's role/policy set for
# CalendarSyncConnection. Owner role bypasses (Employee#owner_role?).
# @see docs/CALENDAR.md
class Companies::CalendarSyncsPolicy < ApplicationPolicy
  def index?;   record.can?(:read,   CalendarSyncConnection) end
  def show?;    record.can?(:read,   CalendarSyncConnection) end
  def new?;     record.can?(:create, CalendarSyncConnection) end
  def create?;  record.can?(:create, CalendarSyncConnection) end
  def edit?;    record.can?(:update, CalendarSyncConnection) end
  def update?;  record.can?(:update, CalendarSyncConnection) end
  def destroy?; record.can?(:delete, CalendarSyncConnection) end
end
