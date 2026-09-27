class Companies::StockTransfersPolicy < ApplicationPolicy
  def index?
    record.can?(:read, StockTransfer)
  end

  def create?
    record.can?(:create, StockTransfer)
  end

  def show?
    record.can?(:read, StockTransfer)
  end

  def new?
    record.can?(:create, StockTransfer)
  end

  def edit?
    record.can?(:update, StockTransfer)
  end

  def update?
    record.can?(:update, StockTransfer)
  end

  def initiate?
    record.can?(:update, StockTransfer)
  end

  def receive?
    record.can?(:update, StockTransfer)
  end

  def cancel?
    record.can?(:update, StockTransfer)
  end
end
