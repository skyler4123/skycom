# spec/models/customer_spec.rb
require 'rails_helper'

RSpec.describe Customer, type: :model do
  describe "associations" do
    it { should belong_to(:user).optional }
    it { should belong_to(:company).optional }
    it { should belong_to(:branch).optional }
    it { should have_many(:orders).dependent(:destroy) }
    it { should have_many(:customer_group_appointments).dependent(:destroy) }
    it { should have_many(:customer_groups).through(:customer_group_appointments) }
    it { should have_many(:role_appointments).dependent(:destroy) }
    it { should have_many(:roles).through(:role_appointments) }
    it { should have_many(:service_appointments).dependent(:destroy) }
    it { should have_many(:services).through(:service_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(individual: 0, small_business: 1, enterprise: 2) }
  end
end
