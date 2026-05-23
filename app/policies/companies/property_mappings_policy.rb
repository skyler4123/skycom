# app/policies/companies/property_mappings_policy.rb
class Companies::PropertyMappingsPolicy < ApplicationPolicy
  def show?
    record.can?(:read, PropertyMapping)
  end

  def create?
    record.can?(:create, PropertyMapping)
  end

  def update?
    record.can?(:update, PropertyMapping)
  end

  def destroy?
    record.can?(:delete, PropertyMapping)
  end
end
