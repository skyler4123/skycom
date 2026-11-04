# frozen_string_literal: true

class Companies::Operations::BasePolicy < ApplicationPolicy
  def show?
    record.can?(:read, Operation)
  end
end
