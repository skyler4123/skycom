# app/policies/companies/stocks_policy.rb
class Companies::StocksPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Stock)
  end
end
