# app/policies/companies/discounts_policy.rb
class Companies::DiscountsPolicy < ApplicationPolicy
  def index?; record.can?(:read, Discount) end
  def show?;  record.can?(:read, Discount) end
end
