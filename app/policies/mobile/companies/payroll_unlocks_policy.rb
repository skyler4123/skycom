# frozen_string_literal: true

class Mobile::Companies::PayrollUnlocksPolicy < ApplicationPolicy
  def new?
    record.can?(:read, Notification)
  end

  def create?
    new?
  end
end
