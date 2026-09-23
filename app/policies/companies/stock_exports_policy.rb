class Companies::StockExportsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, StockExport)
  end

  def create?
    record.can?(:create, StockExport)
  end
end
