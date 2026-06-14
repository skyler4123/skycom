# app/policies/companies/pages_policy.rb
class Companies::PagesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Page)
  end

  def show?
    record.can?(:read, Page)
  end

  def new?
    record.can?(:create, Page)
  end

  def retail_cashier?
    record.can?(:read, Page)
  end

  def create?
    record.can?(:create, Page)
  end

  def edit?
    record.can?(:update, Page)
  end

  def update?
    record.can?(:update, Page)
  end
end
