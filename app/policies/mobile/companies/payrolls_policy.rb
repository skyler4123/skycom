# frozen_string_literal: true

# Self-service: only the signed-in employee's payroll is read, and the
# controller still enforces the password unlock window before rendering.
class Mobile::Companies::PayrollsPolicy < ApplicationPolicy
  def show?
    true
  end
end
