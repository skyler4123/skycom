# frozen_string_literal: true

# PLACEHOLDER POLICY — future Token implementation.
#
# Kept so Companies::Authorizable's auto policy discovery resolves
# Companies::TopUpsPolicy instead of returning "Security Policy not found".
# Refine permissions when the token top-up flow is implemented.
class Companies::TopUpsPolicy < ApplicationPolicy
  # Any employee may see the recovery page. Starting a payment remains
  # permission-gated below.
  def new?
    true
  end

  def mock_qr_gateway?
    record.can?(:read, CompanyPaymentMethod)
  end

  def mock_redirect_gateway?
    record.can?(:read, CompanyPaymentMethod)
  end
end
