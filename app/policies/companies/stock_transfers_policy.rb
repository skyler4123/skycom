class Companies::StockTransfersPolicy < ApplicationPolicy
  def index?
    record.can?(:read, StockTransfer)
  end

  def create?
    record.can?(:create, StockTransfer)
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
