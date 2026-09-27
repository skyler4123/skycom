# spec/models/employee_role_appointment_spec.rb
require 'rails_helper'

RSpec.describe EmployeeRoleAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:role) }
    it { should belong_to(:employee).touch(true) }
  end

  describe "owner role validation" do
    let!(:company) { create(:company) }
    let!(:role) { create(:role, company: company) }

    context "when owner role already exists" do
      let(:existing_owner_appointments) do
        EmployeeRoleAppointment.where(company: company, business_type: :owner)
      end

      it "prevents creating a second owner role" do
        expect(existing_owner_appointments.count).to eq(1)

        other_employee = create(:employee, company: company, business_type: :full_time)
        second_owner = EmployeeRoleAppointment.new(
          company: company,
          role: role,
          employee: other_employee,
          business_type: :owner
        )
        expect(second_owner).not_to be_valid
        expect(second_owner.errors[:base]).to include("Only one owner role assignment is allowed per company.")
      end
    end

    context "when assigning owner role to non-owner employee" do
      let(:non_owner_employee) do
        create(:employee, company: company, business_type: :full_time)
      end

      it "adds validation error" do
        owner_role = EmployeeRoleAppointment.new(
          company: company,
          role: role,
          employee: non_owner_employee,
          business_type: :owner
        )
        expect(owner_role).not_to be_valid
        expect(owner_role.errors[:base]).to include("Owner role can only be assigned to owner employees.")
      end
    end

    context "when creating a non-owner employee_role_appointment" do
      # Use build instead of create to avoid triggering owner validation
      # Company has already created owner employee via initialize_company
      let(:owner_employee) { company.employees.find_by(business_type: :owner) }

      it "allows creation" do
        expect(owner_employee).to be_present
        non_owner = EmployeeRoleAppointment.new(
          company: company,
          role: role,
          employee: owner_employee,
          business_type: nil
        )
        expect(non_owner).to be_valid
      end
    end

    context "when modifying the owner appointment" do
      let(:owner_appointment) do
        EmployeeRoleAppointment.find_by(company: company, business_type: :owner)
      end

      it "blocks update" do
        expect(owner_appointment).to be_present
        expect { owner_appointment.update!(description: "changed") }
          .to raise_error(ActiveRecord::ReadOnlyRecord)
      end

      it "blocks destroy" do
        expect { owner_appointment.destroy! }
          .to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end
  end
end
