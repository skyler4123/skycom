class Companies::CalendarsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Event)
  end
end
