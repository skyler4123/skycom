# spec/models/employee_employee_group_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeEmployeeGroupAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:employee_group) }
  end
end
