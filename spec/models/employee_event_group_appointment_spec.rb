# spec/models/employee_event_group_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeEventGroupAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:event_group) }
  end
end
