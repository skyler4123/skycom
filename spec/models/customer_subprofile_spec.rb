# spec/models/customer_subprofile_spec.rb
require 'rails_helper'

RSpec.describe CustomerSubprofile, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer) }
    it { should belong_to(:customer_profile) }
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
    let(:customer) { create(:customer, company: company) }
    let(:other_customer) { create(:customer, company: company) }
    let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "customer_subprofiles") }
    let(:profile_category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "customer_profiles") }
    let(:profile) { CustomerProfile.create!(company: company, customer: customer, category: profile_category, name: "Profile 1", business_type: :general) }

    it "creates a valid subprofile" do
      sub = CustomerSubprofile.new(company: company, customer: customer, customer_profile: profile, category: category, name: "Subprofile 11", business_type: :general)
      expect(sub).to be_valid
    end

    it "fails when customer mismatches profile customer" do
      sub = CustomerSubprofile.new(company: company, customer: other_customer, customer_profile: profile, category: category, name: "Subprofile 11", business_type: :general)
      expect(sub).not_to be_valid
      expect(sub.errors[:customer]).to be_present
    end
  end
  it_behaves_like "property_mapping concern", CustomerSubprofile
end
