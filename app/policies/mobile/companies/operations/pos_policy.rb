# frozen_string_literal: true

# POS runs inside an Operation, so operators only need Operation read.
class Mobile::Companies::Operations::PosPolicy < ApplicationPolicy
  def show?
    record.can?(:read, Operation)
  end
end
