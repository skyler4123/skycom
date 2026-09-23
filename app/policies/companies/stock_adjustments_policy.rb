class Companies::StockAdjustmentsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, StockAdjustment)
  end

  def create?
    record.can?(:create, StockAdjustment)
  end

  def show?
    record.can?(:read, StockAdjustment)
  end
end
