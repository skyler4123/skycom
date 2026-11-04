# frozen_string_literal: true

class Companies::OperationWarehouseAppointmentsPolicy < ApplicationPolicy
  def show?
    record.can?(:read, Operation)
  end

  def edit?
    record.can?(:update, Operation)
  end

  def update?
    record.can?(:update, Operation)
  end
end
