class Companies::BillingPolicy < ApplicationPolicy
  def show?
    record.can?(:read, BillingContract)
  end

  def pay_all?
    record.can?(:update, BillingContract)
  end

  def toggle_feature?
    record.can?(:update, BillingContract)
  end

  def top_up?
    record.can?(:update, BillingContract)
  end
end
