# frozen_string_literal: true

class Companies::BranchPageAppointmentsPolicy < ApplicationPolicy
  def update?
    record.can?(:update, Page)
  end
end
