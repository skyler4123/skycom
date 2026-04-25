# spec/models/employee_spec.rb
require 'rails_helper'

RSpec.describe Employee, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:user).optional }
    it { should have_many(:role_appointments).dependent(:destroy) }
    it { should have_many(:roles).through(:role_appointments) }
    it { should have_many(:service_appointments).dependent(:destroy) }
    it { should have_many(:services).through(:service_appointments) }
    it { should have_many(:employee_group_appointments).dependent(:destroy) }
    it { should have_many(:employee_groups).through(:employee_group_appointments) }
    it { should have_many(:department_appointments).dependent(:destroy) }
    it { should have_many(:departments).through(:department_appointments) }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
    it { should have_many(:bookings).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
  end

  describe "enums" do
    it { should define_enum_for(:business_type).with_values(owner: 0, full_time: 1, part_time: 2, contractor: 3, intern: 4) }
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
  end
end
