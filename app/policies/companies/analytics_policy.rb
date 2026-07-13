class Companies::AnalyticsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, :analytics)
  end
end
