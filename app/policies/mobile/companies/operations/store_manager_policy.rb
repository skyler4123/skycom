# frozen_string_literal: true

# Store Manager runs inside an Operation, so operators only need Operation read.
class Mobile::Companies::Operations::StoreManagerPolicy < ApplicationPolicy
  def show?
    record.can?(:read, Operation)
  end
end
