# Authorizes bookable devices.
#
# ABAC: every check resolves through the current employee's role/policy set for
# CalendarEquipment. Owner role bypasses (Employee#owner_role?).
# @see docs/CALENDAR.md
class Companies::CalendarEquipmentsPolicy < ApplicationPolicy
  def index?;   record.can?(:read,   CalendarEquipment) end
  def show?;    record.can?(:read,   CalendarEquipment) end
  def new?;     record.can?(:create, CalendarEquipment) end
  def create?;  record.can?(:create, CalendarEquipment) end
  def edit?;    record.can?(:update, CalendarEquipment) end
  def update?;  record.can?(:update, CalendarEquipment) end
  def destroy?; record.can?(:delete, CalendarEquipment) end
end
