# frozen_string_literal: true

class Companies::PayrollsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Payroll)
  end

  def show?
    record.can?(:read, Payroll)
  end

  def my?
    record.can?(:read, Payroll)
  end

  def summary?
    record.can?(:read, Payroll)
  end

  def payrolls?
    record.can?(:read, Payroll)
  end

  def generate?
    record.can?(:create, Payroll)
  end

  def update?
    record.can?(:update, Payroll)
  end
end
