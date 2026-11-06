# frozen_string_literal: true

# MyExamsPolicy — every signed-in employee may use the self-service endpoints;
# the controller scopes every lookup to current_employee.
class Companies::MyExamsPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def start?
    true
  end
end
