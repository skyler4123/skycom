# spec/models/employee_facility_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeFacilityAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:facility) }
  end
end
