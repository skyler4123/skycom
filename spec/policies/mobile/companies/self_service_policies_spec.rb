# frozen_string_literal: true

require "rails_helper"

# Mobile self-service screens are scoped by Mobile::Companies::BaseController to
# the signed-in employee. Their policies stay open to any company member; the
# resource-shaped checks remain on company-level screens.
RSpec.describe "Mobile self-service policies" do
  let(:employee) { instance_double(Employee, can?: false) }

  {
    "profile" => [ Mobile::Companies::EmployeesPolicy, :show? ],
    "attendance month" => [ Mobile::Companies::AttendanceMonthsPolicy, :show? ],
    "payroll" => [ Mobile::Companies::PayrollsPolicy, :show? ],
    "check-in" => [ Mobile::Companies::AttendancesPolicy, :create? ],
    "payroll unlock" => [ Mobile::Companies::PayrollUnlocksPolicy, :new? ],
    "payroll unlock create" => [ Mobile::Companies::PayrollUnlocksPolicy, :create? ]
  }.each do |label, (policy_class, action)|
    it "allows any company member to open their own #{label}" do
      expect(policy_class.new(nil, employee).public_send(action)).to be(true)
    end
  end
end
