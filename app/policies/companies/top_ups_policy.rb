class Companies::TopUpsPolicy < ApplicationPolicy
  def new?
    record.can?(:update, BillingContract)
  end

  def create?
    record.can?(:update, BillingContract)
  end
end
