class Companies::StockPendingsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, StockPending)
  end

  def show?
    record.can?(:read, StockPending)
  end

  def new?
    record.can?(:create, StockPending)
  end

  def create?
    record.can?(:create, StockPending)
  end

  def edit?
    record.can?(:update, StockPending)
  end

  def update?
    record.can?(:update, StockPending)
  end

  def release?
    record.can?(:update, StockPending)
  end

  def cancel?
    record.can?(:update, StockPending)
  end
end
