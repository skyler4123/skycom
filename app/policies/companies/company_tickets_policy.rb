# app/policies/companies/company_tickets_policy.rb
#
# `update` is intentionally narrow: only the visibility column is writable and
# the controller enforces creator-only ownership. Never delegate a generic
# ticket update to `can?(:update)` without re-scoping, or every requester could
# edit every ticket.
class Companies::CompanyTicketsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, CompanyTicket)
  end

  def show?
    record.can?(:read, CompanyTicket)
  end

  def new?
    record.can?(:create, CompanyTicket)
  end

  def create?
    record.can?(:create, CompanyTicket)
  end

  def update?
    record.can?(:update, CompanyTicket)
  end

  def rate?
    record.can?(:update, CompanyTicket)
  end

  def comment?
    record.can?(:create, CompanyTicketComment)
  end
end
