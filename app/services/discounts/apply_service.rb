# frozen_string_literal: true

# == Purpose:
# Reserve a single-use discount code against a pending Order (status "pending").
# The code is consumed only when the resulting Invoice becomes paid
# (Invoice#sync_discount_state); released again by cancel paths. The amount is
# snapshotted onto the Discount at reservation time and is the single source
# for the discounted Invoice price and the campaign budget accounting.
#
# == Returns (never raises for business failures):
#   { success: true, discount: <Discount> } | { success: false, errors: ["..."] }
class Discounts::ApplyService
  def self.call(company:, order:, code:, employee: nil)
    new(company: company, order: order, code: code, employee: employee).call
  end

  def initialize(company:, order:, code:, employee: nil)
    @company = company
    @order = order
    @code = code.to_s.strip.upcase
    @employee = employee
  end

  def call
    ActiveRecord::Base.transaction do
      discount = Discount.where(company: @company, status: :unused).lock.find_by(code: @code)
      return failure("Discount code not found or already used") if discount.nil?

      group = discount.discount_group
      return failure("Discount campaign is not active") unless group.currently_active?
      return failure("Campaign currency does not match the order") unless group.currency.to_s == @order.currency.to_s

      amount = discount.compute_amount_cents(order_subtotal_cents)
      return failure("Discount amount must be greater than zero") unless amount.positive?
      return failure("Campaign budget exhausted") if group.budget_exhausted_with?(amount)

      discount.reserve!(order: @order, employee: @employee, amount_cents: amount)
      { success: true, discount: discount }
    end
  end

  private

  def order_subtotal_cents
    (@order.order_appointments.sum(:total_price) * 100).to_i
  end

  def failure(message)
    { success: false, errors: [ message ] }
  end
end
