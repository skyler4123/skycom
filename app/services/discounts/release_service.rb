# frozen_string_literal: true

# Returns reserved ("pending") codes to the unused pool. Used codes are never
# touched here — their refund reversal flows through Invoice#sync_discount_state
# (Discount#revert!). Pass either a specific discount or an order.
class Discounts::ReleaseService
  def self.call(discount: nil, order: nil)
    scope =
      if discount
        Discount.where(id: discount.id)
      elsif order
        Discount.status_pending.where(order_id: order.id)
      else
        Discount.none
      end

    released = 0
    scope.find_each { |pending| released += 1 if pending.release! }
    { success: true, released: released }
  end
end
