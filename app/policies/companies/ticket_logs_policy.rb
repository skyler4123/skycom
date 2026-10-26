class Companies::TicketLogsPolicy < ApplicationPolicy
  def index?; record.can?(:read, TicketLog) end
  def show?;  record.can?(:read, TicketLog) end
end
