# app/policies/companies/company_tickets_policy.rb
#
# NOTE on `update`: there is no generic `update` endpoint in v1 — the only
# writer besides create is `rate`, gated by `rate?` below (creator-only is
# enforced in the controller). The `update` grant seeded for requester roles
# exists solely for that creator-rate path. If a generic `#update` action is
# ever added, its `update?` must NOT delegate to bare `can?(:update)` without
# re-scoping, or every requester could edit every ticket.
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

  def rate?
    record.can?(:update, CompanyTicket)
  end

  def comment?
    record.can?(:create, CompanyTicketComment)
  end
end
