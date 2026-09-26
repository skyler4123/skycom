# spec/models/employee_notification_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeNotificationAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:notification) }
  end
end
