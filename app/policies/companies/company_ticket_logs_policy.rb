# app/policies/companies/company_ticket_logs_policy.rb
class Companies::CompanyTicketLogsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, CompanyTicketLog)
  end

  def show?
    record.can?(:read, CompanyTicketLog)
  end
end
