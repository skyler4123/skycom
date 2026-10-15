# spec/models/employee_subprofile_spec.rb
require 'rails_helper'

RSpec.describe EmployeeSubprofile, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:employee) }
    it { should belong_to(:employee_profile) }
    it { should belong_to(:category) }
    it { should belong_to(:property_mapping) }
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

  describe "denormalized parent check" do
    let(:company) { create(:company) }
    let(:employee) { create(:employee, company: company) }
    let(:other_employee) { create(:employee, company: company) }
    let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "employee_subprofiles") }
    let(:profile_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "employee_profiles") }
    let(:profile) { EmployeeProfile.create!(company: company, employee: employee, category: profile_category, name: "Profile 1", business_type: :general) }

    it "creates a valid subprofile" do
      sub = EmployeeSubprofile.new(company: company, employee: employee, employee_profile: profile, category: category, name: "Subprofile 11", business_type: :general)
      expect(sub).to be_valid
    end

    it "fails when employee mismatches profile employee" do
      sub = EmployeeSubprofile.new(company: company, employee: other_employee, employee_profile: profile, category: category, name: "Subprofile 11", business_type: :general)
      expect(sub).not_to be_valid
      expect(sub.errors[:employee]).to be_present
    end
  end
  it_behaves_like "property_mapping concern", EmployeeSubprofile
end
