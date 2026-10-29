# spec/models/employee_spec.rb
require 'rails_helper'

RSpec.describe Employee, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:user).optional }
    it { should have_many(:employee_role_appointments).dependent(:destroy) }
    it { should have_many(:roles).through(:employee_role_appointments) }
    it { should have_many(:employee_service_appointments).dependent(:destroy) }
    it { should have_many(:services).through(:employee_service_appointments) }
    it { should have_many(:employee_employee_group_appointments).dependent(:destroy) }
    it { should have_many(:employee_groups).through(:employee_employee_group_appointments) }
    it { should have_many(:department_employee_appointments).dependent(:destroy) }
    it { should have_many(:departments).through(:department_employee_appointments) }
    it { should have_many(:employee_tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:employee_tag_appointments) }
    it { should belong_to(:manager).class_name("Employee").optional }
    it { should have_many(:direct_reports).class_name("Employee").with_foreign_key(:manager_id).dependent(:nullify) }
    it { should have_many(:leave_balances).dependent(:destroy) }
    it { should have_many(:leave_requests).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
  end

  describe "enums" do
    it { should define_enum_for(:business_type).with_values(owner: 0, full_time: 1, part_time: 2, contractor: 3, intern: 4) }
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
  end

  describe "manager assignment" do
    let(:company) { create(:company) }
    let(:manager) { create(:employee, company: company) }

    it "accepts a manager from the same company" do
      employee = create(:employee, company: company, manager: manager)
      expect(employee).to be_valid
      expect(employee.manager).to eq(manager)
    end

    it "rejects a manager from another company" do
      other_manager = create(:employee, company: create(:company))
      employee = build(:employee, company: company, manager: other_manager)
      expect(employee).not_to be_valid
      expect(employee.errors[:manager]).to be_present
    end

    it "rejects reporting to yourself" do
      employee = create(:employee, company: company)
      employee.manager_id = employee.id
      expect(employee).not_to be_valid
      expect(employee.errors[:manager]).to be_present
    end

    it "nullifies direct reports when the manager is destroyed" do
      report = create(:employee, company: company, manager: manager)
      manager.destroy!
      expect(report.reload.manager_id).to be_nil
    end
  end

  describe "owner uniqueness validation" do
    let!(:company) { create(:company) }
    let!(:existing_owner) { company.employees.find_by(business_type: :owner) }

    context "when trying to create a second owner employee" do
      it "adds a validation error" do
        expect(existing_owner).to be_present
        second_owner = Employee.new(company: company, name: "Another Owner", business_type: :owner)
        expect(second_owner).not_to be_valid
        expect(second_owner.errors[:base]).to include("Only one owner employee is allowed per company.")
      end
    end

    context "when creating a non-owner employee" do
      it "allows creation" do
        non_owner = Employee.new(company: company, name: "Regular Employee", business_type: :full_time)
        expect(non_owner).to be_valid
      end
    end
  end

  describe "owner employee protection" do
    let!(:company) { create(:company) }
    let!(:owner_employee) { company.employees.find_by(business_type: :owner) }

    context "when trying to discard an owner employee" do
      it "does not discard and raises an error" do
        expect { owner_employee.discard! }.to raise_error(Discard::RecordNotDiscarded)
        owner_employee.reload
        expect(owner_employee.discarded?).to be_falsey
      end
    end

    context "when trying to discard a non-owner employee" do
      let!(:non_owner) { create(:employee, company: company, business_type: :full_time) }

      it "allows discard" do
        expect { non_owner.discard! }.not_to raise_error
        non_owner.reload
        expect(non_owner.discarded?).to be_truthy
      end
    end
  end
  it_behaves_like "property_mapping concern", Employee
end
