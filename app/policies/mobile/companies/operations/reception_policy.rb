# frozen_string_literal: true

# Reception runs inside an Operation, so operators only need Operation read.
class Mobile::Companies::Operations::ReceptionPolicy < ApplicationPolicy
  def show?
    record.can?(:read, Operation)
  end
end
