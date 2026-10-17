class Companies::StoredFilesPolicy < ApplicationPolicy
  def index?
    record.can?(:read, StoredFile)
  end

  def show?
    record.can?(:read, StoredFile)
  end

  def create?
    record.can?(:create, StoredFile)
  end

  def update?
    record.can?(:update, StoredFile)
  end

  def download?
    record.can?(:read, StoredFile)
  end

  def destroy?
    record.can?(:delete, StoredFile)
  end
end
