# spec/models/role_spec.rb
require 'rails_helper'

RSpec.describe Role, type: :model do
  describe "associations" do
    it { should belong_to(:company).touch(true) }
    it { should belong_to(:branch).optional }
    it { should have_many(:policy_appointments).dependent(:destroy) }
    it { should have_many(:policies).through(:policy_appointments) }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
    it { should have_many(:role_appointments).dependent(:destroy) }
    it { should have_many(:employees).through(:role_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
    it { should validate_length_of(:name).is_at_most(100) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(administrative: 0, management: 1, technical: 2, support: 3) }
    it { should define_enum_for(:model_type) }
  end
end