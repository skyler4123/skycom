# frozen_string_literal: true

class Companies::ExamsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Exam)
  end

  def show?
    record.can?(:read, Exam)
  end

  def new?
    record.can?(:create, Exam)
  end

  def create?
    record.can?(:create, Exam)
  end

  def edit?
    record.can?(:update, Exam)
  end

  def update?
    record.can?(:update, Exam)
  end

  def destroy?
    record.can?(:delete, Exam)
  end

  def publish?
    record.can?(:update, Exam)
  end

  def archive?
    record.can?(:update, Exam)
  end

  def refresh_summary?
    record.can?(:update, Exam)
  end
end
