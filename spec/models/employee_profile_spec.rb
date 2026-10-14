# spec/models/employee_profile_spec.rb
require 'rails_helper'

RSpec.describe EmployeeProfile, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:category) }
    it { should belong_to(:property_mapping) }
    it { should have_many(:employee_subprofiles).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(general: 0, special: 1) }
  end

  describe "parent scoping" do
    let(:company) { create(:company) }
    let(:employee) { create(:employee, company: company) }
    let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "employee_profiles") }

    it "creates a valid profile" do
      profile = EmployeeProfile.new(company: company, employee: employee, category: category, name: "Profile 1", business_type: :general)
      expect(profile).to be_valid
    end

    it "fails without name" do
      profile = EmployeeProfile.new(company: company, employee: employee, category: category, name: nil, business_type: :general)
      expect(profile).not_to be_valid
      expect(profile.errors[:name]).to be_present
    end
  end
  it_behaves_like "property_mapping concern", EmployeeProfile
end
