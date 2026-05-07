# app/policies/companies/stock_transfers_policy.rb
class Companies::StockTransfersPolicy < ApplicationPolicy
  def index?
    record.can?(:read, StockTransfer)
  end
end
