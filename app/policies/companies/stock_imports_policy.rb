class Companies::StockImportsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, StockImport)
  end

  def create?
    record.can?(:create, StockImport)
  end
end
