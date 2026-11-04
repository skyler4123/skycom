# frozen_string_literal: true

class Companies::OperationConfigsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Operation)
  end

  def update?
    record.can?(:update, Operation)
  end
end
