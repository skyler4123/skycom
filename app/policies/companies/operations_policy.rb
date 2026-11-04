# frozen_string_literal: true

class Companies::OperationsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Operation)
  end

  def launch?
    record.can?(:read, Operation)
  end
end
