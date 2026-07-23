# frozen_string_literal: true

class Companies::PaymentMethodAppointmentsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, PaymentMethodAppointment)
  end

  def edit?
    record.can?(:read, PaymentMethodAppointment)
  end

  def update?
    record.can?(:update, PaymentMethodAppointment)
  end
end
