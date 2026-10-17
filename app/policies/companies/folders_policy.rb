class Companies::FoldersPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Folder)
  end

  def show?
    record.can?(:read, Folder)
  end

  def create?
    record.can?(:create, Folder)
  end

  def update?
    record.can?(:update, Folder)
  end

  def destroy?
    record.can?(:delete, Folder)
  end
end
