class Companies::TicketsPolicy < ApplicationPolicy
  def index?;    record.can?(:read,   Ticket) end
  def show?;     record.can?(:read,   Ticket) end
  def new?;      record.can?(:create, Ticket) end
  def create?;   record.can?(:create, Ticket) end
  def edit?;     record.can?(:update, Ticket) end
  def update?;   record.can?(:update, Ticket) end
  def destroy?;  record.can?(:delete, Ticket) end
  def advance?;  record.can?(:update, Ticket) end
  def assign?;   record.can?(:update, Ticket) end
end
