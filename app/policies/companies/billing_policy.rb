# frozen_string_literal: true

class Companies::BillingPolicy < ApplicationPolicy
  def show?
    record.can?(:read, CompanyOrder)
  end
end
