# spec/models/employee_project_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeProjectAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:project) }
  end
end
