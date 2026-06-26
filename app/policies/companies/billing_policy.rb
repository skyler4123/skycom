# frozen_string_literal: true

class Companies::BillingPolicy < ApplicationPolicy
  def show?
    true
  end

  def pay_all?
    true
  end
end
