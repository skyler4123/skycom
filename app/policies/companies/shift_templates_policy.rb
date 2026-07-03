class Companies::ShiftTemplatesPolicy < ApplicationPolicy
  def index?;  record.can?(:read,   ShiftTemplate) end
  def show?;   record.can?(:read,   ShiftTemplate) end
  def new?;    record.can?(:create, ShiftTemplate) end
  def create?; record.can?(:create, ShiftTemplate) end
  def edit?;   record.can?(:update, ShiftTemplate) end
  def update?; record.can?(:update, ShiftTemplate) end
end
