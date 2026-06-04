# spec/models/employee_spec.rb
require 'rails_helper'

RSpec.describe Employee, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:user).optional }
    it { should have_many(:role_appointments).dependent(:destroy) }
    it { should have_many(:roles).through(:role_appointments) }
    it { should have_many(:service_appointments).dependent(:destroy) }
    it { should have_many(:services).through(:service_appointments) }
    it { should have_many(:employee_group_appointments).dependent(:destroy) }
    it { should have_many(:employee_groups).through(:employee_group_appointments) }
    it { should have_many(:department_appointments).dependent(:destroy) }
    it { should have_many(:departments).through(:department_appointments) }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
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
