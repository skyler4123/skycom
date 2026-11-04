# frozen_string_literal: true

# Operations lists the company's accessible Operations, so it requires Operation read.
class Mobile::Companies::OperationsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Operation)
  end
end
