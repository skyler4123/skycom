# spec/models/employee_exam_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeExamAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:exam) }
  end
end
