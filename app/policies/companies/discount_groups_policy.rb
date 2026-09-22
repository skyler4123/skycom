# app/policies/companies/discount_groups_policy.rb
class Companies::DiscountGroupsPolicy < ApplicationPolicy
  def index?;    record.can?(:read,   DiscountGroup) end
  def show?;     record.can?(:read,   DiscountGroup) end
  def new?;      record.can?(:create, DiscountGroup) end
  def create?;   record.can?(:create, DiscountGroup) end
  def edit?;     record.can?(:update, DiscountGroup) end
  def update?;   record.can?(:update, DiscountGroup) end
  def destroy?;  record.can?(:delete, DiscountGroup) end

  # generate_codes maps to the ABAC update action.
  def generate_codes?; record.can?(:update, DiscountGroup) end
end
