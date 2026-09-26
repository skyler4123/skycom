# spec/models/employee_employee_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeEmployeeAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:related_employee) }
  end
end
