# frozen_string_literal: true

class Mobile::Companies::OperationsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Notification)
  end
end
