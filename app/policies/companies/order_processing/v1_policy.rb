# frozen_string_literal: true

class Companies::OrderProcessing::V1Policy < ApplicationPolicy
  def checkout?
    record.can?(:create, Order)
  end

  def pay?
    record.can?(:update, Order)
  end

  def pay_cancel?
    record.can?(:update, Order)
  end

  def apply_discount?
    pay?
  end

  def remove_discount?
    pay?
  end

  def cancel?
    pay?
  end
end
