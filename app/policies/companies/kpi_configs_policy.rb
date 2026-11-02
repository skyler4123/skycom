class Companies::KpiConfigsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, KpiConfig)
  end

  def create?
    record.can?(:create, KpiConfig)
  end

  def update?
    record.can?(:update, KpiConfig)
  end

  def destroy?
    record.can?(:delete, KpiConfig)
  end
end
