class Companies::PerformancePolicy < ApplicationPolicy
  def index?
    record.can?(:read, KpiConfig)
  end

  def show?
    record.can?(:read, KpiConfig)
  end
end
