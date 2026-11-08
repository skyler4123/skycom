# frozen_string_literal: true

# Inventory runs inside an Operation, so operators only need Operation read.
class Mobile::Companies::Operations::InventoryPolicy < ApplicationPolicy
  def show?
    record.can?(:read, Operation)
  end
end
