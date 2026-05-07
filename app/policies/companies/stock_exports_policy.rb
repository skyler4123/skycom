# app/policies/companies/stock_exports_policy.rb
class Companies::StockExportsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, StockExport)
  end
end
