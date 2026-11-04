# frozen_string_literal: true

class Companies::PageConfigsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Page)
  end

  def update?
    record.can?(:update, Page)
  end
end
