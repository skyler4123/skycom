# frozen_string_literal: true

class Companies::PageWarehouseAppointmentsPolicy < ApplicationPolicy
  def update?
    record.can?(:update, Page)
  end
end
