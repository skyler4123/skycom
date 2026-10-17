class Companies::StorageStatisticsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, StoredFile)
  end
end
