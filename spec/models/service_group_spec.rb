# spec/models/service_group_spec.rb
require 'rails_helper'

RSpec.describe ServiceGroup, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should have_many(:service_group_appointments).dependent(:destroy) }
    it { should have_many(:services).through(:service_group_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
    it { should validate_presence_of(:start_at) }
    it { should validate_presence_of(:code) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "validations :duration" do
    it { should allow_value(nil).for(:duration) }
    it { should allow_value(0).for(:duration) }
    it { should allow_value(120).for(:duration) }
    it { should_not allow_value(-1).for(:duration) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(consulting: 0, maintenance: 1, support: 2, training: 3) }
  end
end