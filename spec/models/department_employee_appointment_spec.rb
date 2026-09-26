# spec/models/department_employee_appointment_spec.rb
require "rails_helper"

RSpec.describe DepartmentEmployeeAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:department) }
    it { should belong_to(:employee) }
  end
end
