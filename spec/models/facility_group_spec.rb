# spec/models/facility_group_spec.rb
require 'rails_helper'

RSpec.describe FacilityGroup, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should have_many(:facility_group_appointments).dependent(:destroy) }
    it { should have_many(:facilities).through(:facility_group_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
    it { should validate_presence_of(:code) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(building: 0, floor: 1, wing: 2) }
  end
end
