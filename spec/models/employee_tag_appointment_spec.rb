# spec/models/employee_tag_appointment_spec.rb
require 'rails_helper'

RSpec.describe EmployeeTagAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:tag) }
    it { should belong_to(:employee) }
  end

  describe ".attach_tag" do
    let!(:company) { create(:company) }
    let!(:employee) { create(:employee, company: company, business_type: :full_time) }

    it "creates an atomic appointment" do
      appointment = employee.attach_tag(key: "skill", value: "ruby")
      expect(appointment).to be_a(EmployeeTagAppointment)
      expect(appointment).to be_persisted
      expect(employee.tags.map(&:key)).to include("skill")
    end

    it "resolves the appointment class from the record class" do
      expect(TagConcern.tag_appointment_class_for(Employee)).to eq(EmployeeTagAppointment)
      expect(TagConcern.tag_appointment_class_for(Task)).to eq(TagTaskAppointment)
      expect(Employee.tag_appointment_class_for(Employee)).to eq(EmployeeTagAppointment)
    end
  end
end
