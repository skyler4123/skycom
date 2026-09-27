# spec/models/employee_setting_group_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeSettingGroupAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:setting_group) }
  end
end
