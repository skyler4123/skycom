# app/policies/companies/refunds_policy.rb
class Companies::RefundsPolicy < ApplicationPolicy
  def index?;    record.can?(:read,   Refund) end
  def show?;     record.can?(:read,   Refund) end
  def new?;      record.can?(:create, Refund) end
  def create?;   record.can?(:create, Refund) end
  def edit?;     record.can?(:update, Refund) end
  def update?;   record.can?(:update, Refund) end

  def advance?;  record.can?(:update, Refund) end
end
