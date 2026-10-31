# frozen_string_literal: true

# Self-service: any member may confirm their own password. The unlock is
# scoped to the current company and expires after MOBILE_PAYROLL_UNLOCK_WINDOW.
class Mobile::Companies::PayrollUnlocksPolicy < ApplicationPolicy
  def new?
    true
  end

  def create?
    new?
  end
end
