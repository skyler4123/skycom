# frozen_string_literal: true

class Mobile::Companies::PayrollsPolicy < ApplicationPolicy
  def show?
    record.can?(:read, Notification)
  end
end
