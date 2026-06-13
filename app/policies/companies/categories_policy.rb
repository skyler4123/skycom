class Companies::CategoriesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Category)
  end

  def show?
    record.can?(:read, Category)
  end

  def new?
    record.can?(:create, Category)
  end

  def create?
    record.can?(:create, Category)
  end

  def edit?
    record.can?(:update, Category)
  end

  def update?
    record.can?(:update, Category)
  end
end
