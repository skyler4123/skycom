# frozen_string_literal: true

class Companies::PagesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Page)
  end

  def launch?
    record.can?(:read, Page)
  end
end
