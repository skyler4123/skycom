# frozen_string_literal: true

class Companies::Pages::BasePolicy < ApplicationPolicy
  def show?
    record.can?(:read, Page)
  end
end
