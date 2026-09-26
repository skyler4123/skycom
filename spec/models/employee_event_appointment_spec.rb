# spec/models/employee_event_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeEventAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:event) }
  end
end
