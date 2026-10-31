# frozen_string_literal: true

# Operations lists the company's operating Pages, so it requires Page read.
class Mobile::Companies::OperationsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Page)
  end
end
