# app/policies/companies/branches_policy.rb
class Companies::BranchesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Branch)
  end

  def show?
    record.can?(:read, Branch)
  end

  def new?
    record.can?(:create, Branch)
  end

  def create?
    record.can?(:create, Branch)
  end

  def edit?
    record.can?(:update, Branch)
  end

  def update?
    record.can?(:update, Branch)
  end
end
