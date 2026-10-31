# spec/models/employee_group_spec.rb
require 'rails_helper'

RSpec.describe EmployeeGroup, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:manager).class_name("Employee").optional }
    it { should belong_to(:category) }
    it { should have_many(:employee_employee_group_appointments).dependent(:destroy) }
    it { should have_many(:employees).through(:employee_employee_group_appointments) }
    it { should have_many(:employee_group_role_appointments).dependent(:destroy) }
    it { should have_many(:roles).through(:employee_group_role_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "manager assignment" do
    let(:company) { create(:company) }
    let(:manager) { create(:employee, company: company) }
    let(:employee_group) { build(:employee_group, company: company, manager: manager) }

    it "accepts a manager from the same company" do
      expect(employee_group).to be_valid
      expect(employee_group.manager).to eq(manager)
    end

    it "rejects a manager from another company" do
      employee_group.manager = create(:employee, company: create(:company))

      expect(employee_group).not_to be_valid
      expect(employee_group.errors[:manager]).to be_present
    end

    it "allows a group without a manager" do
      employee_group.manager = nil

      expect(employee_group).to be_valid
    end
  end
  it_behaves_like "property_mapping concern", EmployeeGroup
end
