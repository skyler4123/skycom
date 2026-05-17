# app/policies/companies/category_policy.rb
class Companies::CategoriesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Category)
  end

  def create?
    record.can?(:create, Category)
  end

  def update?
    record.can?(:update, Category)
  end
end
