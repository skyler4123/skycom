# frozen_string_literal: true

class Companies::TaxesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Invoice) || record.can?(:read, Purchase) || record.can?(:read, StockExport)
  end

  def summary?
    index?
  end

  def invoices?
    record.can?(:read, Invoice)
  end

  def purchases?
    record.can?(:read, Purchase)
  end

  def stock_exports?
    record.can?(:read, StockExport)
  end
end
