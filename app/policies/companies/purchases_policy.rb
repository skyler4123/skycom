# app/policies/companies/purchases_policy.rb
class Companies::PurchasesPolicy < ApplicationPolicy
  def index?;    record.can?(:read,   Purchase) end
  def show?;     record.can?(:read,   Purchase) end
  def new?;      record.can?(:create, Purchase) end
  def create?;   record.can?(:create, Purchase) end
  def edit?;     record.can?(:update, Purchase) end
  def update?;   record.can?(:update, Purchase) end

  # advance maps to the ABAC update action (same check AdvanceService enforces).
  def advance?;  record.can?(:update, Purchase) end
end
