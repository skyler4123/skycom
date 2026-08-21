# frozen_string_literal: true

class Companies::UsagePolicy < ApplicationPolicy
  def show?
    record.can?(:read, CompanyWallet)
  end
end
