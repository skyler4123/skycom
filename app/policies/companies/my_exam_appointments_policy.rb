# frozen_string_literal: true

# MyExamAppointmentsPolicy — every signed-in employee may use the self-service
# attempt endpoints; the controller scopes every lookup to current_employee.
class Companies::MyExamAppointmentsPolicy < ApplicationPolicy
  def show?
    true
  end

  def take?
    true
  end

  def answer?
    true
  end

  def submit?
    true
  end
end
