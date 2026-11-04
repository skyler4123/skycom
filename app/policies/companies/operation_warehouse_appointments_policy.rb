# frozen_string_literal: true

class Companies::OperationWarehouseAppointmentsPolicy < ApplicationPolicy
  def update?
    record.can?(:update, Operation)
  end
end
