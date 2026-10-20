class Companies::TicketCommentsPolicy < ApplicationPolicy
  def create?; record.can?(:create, TicketComment) end
end