# app/policies/companies/property_mappings_policy.rb
class Companies::PropertyMappingsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, PropertyMapping)
  end

  def show?
    record.can?(:read, PropertyMapping)
  end

  def new?
    record.can?(:create, PropertyMapping)
  end

  def create?
    record.can?(:create, PropertyMapping)
  end

  def edit?
    record.can?(:update, PropertyMapping)
  end

  def update?
    record.can?(:update, PropertyMapping)
  end

  def destroy?
    record.can?(:delete, PropertyMapping)
  end
end
