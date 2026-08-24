# frozen_string_literal: true

class Companies::UsagePolicy < ApplicationPolicy
  def show?
    record.can?(:read, CompanyWallet)
  end

  def enable_logging?
    record.can?(:update, CompanyWallet)
  end

  def disable_logging?
    record.can?(:update, CompanyWallet)
  end
end
