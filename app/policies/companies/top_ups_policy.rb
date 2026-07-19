class Companies::TopUpsPolicy < ApplicationPolicy
  def new?
    record.can?(:read, BillingPaymentMethod)
  end

  def mock_qr_gateway?
    record.can?(:create, BillingTransaction)
  end

  def mock_redirect_gateway?
    record.can?(:create, BillingTransaction)
  end
end
