# frozen_string_literal: true

# Financial analytics follows invoice visibility. The owner bypass lives in
# Employee#can?, so Admin/Manager roles with Invoice read can open the page;
# roles without money visibility cannot.
class Companies::AnalyticsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Invoice)
  end
end
