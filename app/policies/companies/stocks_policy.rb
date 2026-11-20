# app/policies/companies/stocks_policy.rb
# The stock list and the stock-row screen are the same read permission.
class Companies::StocksPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Stock)
  end

  def show?
    record.can?(:read, Stock)
  end
end
