# spec/models/concerns/role_concern_spec.rb
require 'rails_helper'

RSpec.describe RoleConcern do
  describe "when included in an ActiveRecord model" do
    it "adds employee_role_appointments association to Employee" do
      expect(Employee.reflect_on_association(:employee_role_appointments)).to be_a(ActiveRecord::Reflection::HasManyReflection)
    end

    it "adds roles association through employee_role_appointments to Employee" do
      expect(Employee.reflect_on_association(:roles)).to be_a(ActiveRecord::Reflection::ThroughReflection)
    end

    it "adds customer_role_appointments association to Customer" do
      expect(Customer.reflect_on_association(:customer_role_appointments)).to be_a(ActiveRecord::Reflection::HasManyReflection)
    end
  end

  describe "#attach_role" do
    let!(:company) { create(:company) }
    let!(:employee) { create(:employee, company: company, business_type: :full_time) }

    it "creates an EmployeeRoleAppointment" do
      expect { employee.attach_role("Seller") }
        .to change(EmployeeRoleAppointment, :count).by(1)
      expect(employee.has_role?("Seller")).to be true
    end

    it "is idempotent" do
      employee.attach_role("Seller")
      expect { employee.attach_role("Seller") }
        .not_to change(EmployeeRoleAppointment, :count)
    end
  end
end
