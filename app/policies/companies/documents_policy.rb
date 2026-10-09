class Companies::DocumentsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Document)
  end

  def show?
    record.can?(:read, Document)
  end

  def new?
    record.can?(:create, Document)
  end

  def create?
    record.can?(:create, Document)
  end

  def edit?
    record.can?(:update, Document)
  end

  def update?
    record.can?(:update, Document)
  end
end
