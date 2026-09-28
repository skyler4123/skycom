class Companies::StockExportsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, StockExport)
  end

  def create?
    record.can?(:create, StockExport)
  end

  def show?
    record.can?(:read, StockExport)
  end

  def new?
    record.can?(:create, StockExport)
  end

  def edit?
    record.can?(:update, StockExport)
  end
end
