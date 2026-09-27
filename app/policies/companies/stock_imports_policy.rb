class Companies::StockImportsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, StockImport)
  end

  def create?
    record.can?(:create, StockImport)
  end

  def show?
    record.can?(:read, StockImport)
  end

  def new?
    record.can?(:create, StockImport)
  end
end
