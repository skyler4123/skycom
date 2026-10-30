# spec/models/employee_employee_group_appointment_spec.rb
require "rails_helper"

RSpec.describe EmployeeEmployeeGroupAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:employee_group) }
  end

  describe "employee managers cache" do
    let(:company) { create(:company) }
    let(:employee) { create(:employee, company: company) }
    let(:manager) { create(:employee, company: company) }
    let(:employee_group) { create(:employee_group, company: company, manager: manager) }

    it "clears the employee's cached managers when created and destroyed" do
      employee.managers

      appointment = create(
        :employee_employee_group_appointment,
        company: company,
        employee: employee,
        employee_group: employee_group
      )

      expect(employee.managers).to contain_exactly(manager)

      appointment.destroy!

      expect(employee.managers).to be_empty
    end
  end
end
