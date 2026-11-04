# frozen_string_literal: true

class Companies::BranchOperationAppointmentsPolicy < ApplicationPolicy
  def update?
    record.can?(:update, Operation)
  end
end
