# app/policies/companies/stock_imports_policy.rb
class Companies::StockImportsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, StockImport)
  end
end
