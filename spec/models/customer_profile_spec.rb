# spec/models/customer_profile_spec.rb
require 'rails_helper'

RSpec.describe CustomerProfile, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:customer) }
    it { should belong_to(:category) }
    it { should belong_to(:property_mapping) }
    it { should have_many(:customer_subprofiles).dependent(:destroy) }
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
    let(:customer) { create(:customer, company: company) }
    let(:category) { Seed::CategoryService.find_or_create_for(company: company, resource_name: "customer_profiles") }

    it "creates a valid profile" do
      profile = CustomerProfile.new(company: company, customer: customer, category: category, name: "Profile 1", business_type: :general)
      expect(profile).to be_valid
    end

    it "fails without name" do
      profile = CustomerProfile.new(company: company, customer: customer, category: category, name: nil, business_type: :general)
      expect(profile).not_to be_valid
      expect(profile.errors[:name]).to be_present
    end

    it "fails when customer belongs to another company" do
      other = create(:company)
      foreign_customer = create(:customer, company: other)
      profile = CustomerProfile.new(company: company, customer: foreign_customer, category: category, name: "Profile 1", business_type: :general)
      expect(profile).not_to be_valid
      expect(profile.errors[:customer]).to be_present
    end

    it "discarding cascades to subprofiles" do
      profile = Seed::CustomerProfileService.create(company: company, customer: customer, category: category, name: "Profile 1")
      sub = Seed::CustomerSubprofileService.create(company: company, customer: customer, customer_profile: profile, name: "Subprofile 11")
      profile.discard!
      expect(sub.reload.discarded?).to be_truthy
    end
  end
  it_behaves_like "property_mapping concern", CustomerProfile
end
