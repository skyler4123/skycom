# spec/models/employee_manager_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeManagerAppointment, type: :model do
  describe "table" do
    it "uses employee_manager_appointments" do
      expect(described_class.table_name).to eq("employee_manager_appointments")
    end
  end

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:manager_employee).class_name("Employee") }
  end

  describe "enums" do
    it { should define_enum_for(:relationship_type).with_prefix(true).with_values(primary: 0, dotted: 1, mentor: 2) }
  end

describe "reporting line" do
  it "refuses to make an employee their own manager" do
    id = SecureRandom.uuid
    appointment = described_class.new(employee_id: id, manager_employee_id: id)
    appointment.valid?

    expect(appointment.errors[:manager_employee]).to include("cannot be the employee themselves")
  end
end
end
