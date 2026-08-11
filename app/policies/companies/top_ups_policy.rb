# frozen_string_literal: true

# PLACEHOLDER POLICY — future Token implementation.
#
# Kept so Companies::Authorizable's auto policy discovery resolves
# Companies::TopUpsPolicy instead of returning "Security Policy not found".
# Refine permissions when the token top-up flow is implemented.
class Companies::TopUpsPolicy < ApplicationPolicy
  def new?
    record.can?(:read, BillingPaymentMethod)
  end

  def mock_qr_gateway?
    record.can?(:read, BillingPaymentMethod)
  end

  def mock_redirect_gateway?
    record.can?(:read, BillingPaymentMethod)
  end
end
