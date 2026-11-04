# frozen_string_literal: true

class Companies::OperationConfigsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Operation)
  end

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
