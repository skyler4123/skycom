# frozen_string_literal: true

class Companies::ExamAssignmentsPolicy < ApplicationPolicy
  def index?
    record.can?(:update, Exam)
  end

  def create?
    record.can?(:update, Exam)
  end
end
