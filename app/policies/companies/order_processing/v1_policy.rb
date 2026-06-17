# frozen_string_literal: true

class Companies::OrderProcessing::V1Policy < ApplicationPolicy
  def checkout?
    record.can?(:create, Order)
  end

  def pay?
    record.can?(:update, Order)
  end
end
