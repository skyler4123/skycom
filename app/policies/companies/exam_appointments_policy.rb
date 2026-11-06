# frozen_string_literal: true

class Companies::ExamAppointmentsPolicy < ApplicationPolicy
  def index?
    record.can?(:read, Exam)
  end

  def show?
    record.can?(:read, Exam)
  end

  def grade?
    record.can?(:update, Exam)
  end
end
