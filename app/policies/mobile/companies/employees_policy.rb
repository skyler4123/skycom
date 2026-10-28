# frozen_string_literal: true

class Mobile::Companies::EmployeesPolicy < ApplicationPolicy
  def show?
    record.can?(:read, Notification)
  end
end
