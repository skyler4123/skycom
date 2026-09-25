# spec/models/employee_setting_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeSettingAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:setting) }
  end
end
