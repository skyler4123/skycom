# spec/models/role_appointment_spec.rb
require 'rails_helper'

RSpec.describe RoleAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:role) }
    it { should belong_to(:appoint_to) }
  end

  describe "owner role validation" do
    let!(:company) { create(:company) }
    let!(:role) { create(:role, company: company) }

    context "when owner role already exists" do
      let(:existing_owner_appointments) do
        RoleAppointment.where(company: company, business_type: :owner)
      end

      it "prevents creating a second owner role" do
        expect(existing_owner_appointments.count).to eq(1)

        # Use an existing non-owner employee from company setup
        existing_employee = company.employees.where.not(business_type: :owner).first
        second_owner = RoleAppointment.new(
          company: company,
          role: role,
          appoint_to: existing_employee,
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
        owner_role = RoleAppointment.new(
          company: company,
          role: role,
          appoint_to: non_owner_employee,
          business_type: :owner
        )
        expect(owner_role).not_to be_valid
        expect(owner_role.errors[:base]).to include("Owner role can only be assigned to owner employees.")
      end
    end

    context "when creating a non-owner role_appointment" do
      # Use build instead of create to avoid triggering owner validation
      # Company has already created owner employee via setup_owner_records
      let(:owner_employee) { company.employees.find_by(business_type: :owner) }

      it "allows creation" do
        expect(owner_employee).to be_present
        non_owner = RoleAppointment.new(
          company: company,
          role: role,
          appoint_to: owner_employee,
          business_type: nil
        )
        expect(non_owner).to be_valid
      end
    end
  end
end
