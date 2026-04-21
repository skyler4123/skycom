# spec/models/policy_spec.rb
require 'rails_helper'

RSpec.describe Policy, type: :model do
  describe "associations" do
    it { should belong_to(:company).touch(true) }
    it { should belong_to(:branch).optional }
    it { should have_many(:policy_appointments).dependent(:destroy) }
    it { should have_many(:roles).through(:policy_appointments) }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:resource) }
    it { should validate_presence_of(:action) }
    it { should validate_length_of(:name).is_at_most(150) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(security: 0, regulatory: 1, operational: 2, compliance: 3) }
  end
end
