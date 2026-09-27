# frozen_string_literal: true

# Single policy for the payment-methods UI (company + branch rows share one
# controller). Governed by the CompanyPaymentMethodAppointment resource.
class Companies::PaymentMethodAppointmentsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, CompanyPaymentMethodAppointment)
  end

  def edit?
    record.can?(:read, CompanyPaymentMethodAppointment)
  end

  def update?
    record.can?(:update, CompanyPaymentMethodAppointment)
  end
end
