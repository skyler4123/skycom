# frozen_string_literal: true

class Companies::QuestionsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Question)
  end

  def show?
    record.can?(:read, Question)
  end

  def new?
    record.can?(:create, Question)
  end

  def create?
    record.can?(:create, Question)
  end

  def edit?
    record.can?(:update, Question)
  end

  def update?
    record.can?(:update, Question)
  end

  def destroy?
    record.can?(:delete, Question)
  end
end
