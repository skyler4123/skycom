# app/policies/companies/company_ticket_comments_policy.rb
class Companies::CompanyTicketCommentsPolicy < ApplicationPolicy
  def create?
    record.can?(:create, CompanyTicketComment)
  end
end
