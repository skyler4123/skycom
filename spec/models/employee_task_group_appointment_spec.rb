# spec/models/employee_task_group_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeTaskGroupAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:task_group) }
  end
end
