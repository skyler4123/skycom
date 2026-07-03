class Companies::SchedulesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, ScheduledShift)
  end
end
