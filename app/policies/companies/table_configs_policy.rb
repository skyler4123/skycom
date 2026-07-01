# app/policies/companies/table_configs_policy.rb
class Companies::TableConfigsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, TableConfig)
  end

  def show?
    record.can?(:read, TableConfig)
  end

  def new?
    record.can?(:create, TableConfig)
  end

  def create?
    record.can?(:create, TableConfig)
  end

  def edit?
    record.can?(:update, TableConfig)
  end

  def update?
    record.can?(:update, TableConfig)
  end
end
