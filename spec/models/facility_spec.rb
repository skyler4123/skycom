# spec/models/facility_spec.rb
require 'rails_helper'

RSpec.describe Facility, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should have_many(:facility_group_appointments).dependent(:destroy) }
    it { should have_many(:facility_groups).through(:facility_group_appointments) }
    it { should have_many(:bookings).dependent(:destroy) }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(5000) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(publicly_traded: 0, privately_held: 1) }
  end
end