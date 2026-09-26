# spec/models/employee_service_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeServiceAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:service) }
  end
end
