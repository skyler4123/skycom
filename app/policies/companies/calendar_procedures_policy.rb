# Authorizes bookable appointment types.
#
# ABAC: every check resolves through the current employee's role/policy set for
# CalendarProcedure. Owner role bypasses (Employee#owner_role?).
# @see docs/CALENDAR.md
class Companies::CalendarProceduresPolicy < ApplicationPolicy
  def index?;   record.can?(:read,   CalendarProcedure) end
  def show?;    record.can?(:read,   CalendarProcedure) end
  def new?;     record.can?(:create, CalendarProcedure) end
  def create?;  record.can?(:create, CalendarProcedure) end
  def edit?;    record.can?(:update, CalendarProcedure) end
  def update?;  record.can?(:update, CalendarProcedure) end
  def destroy?; record.can?(:delete, CalendarProcedure) end
end
