# frozen_string_literal: true

class Companies::PayrollConfigsPolicy < ApplicationPolicy
  def show?
    record.can?(:read, Payroll)
  end

  def update?
    record.can?(:update, Payroll)
  end
end
