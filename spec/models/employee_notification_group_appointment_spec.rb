# spec/models/employee_notification_group_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeNotificationGroupAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:notification_group) }
  end
end
