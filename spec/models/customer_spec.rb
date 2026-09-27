# spec/models/customer_spec.rb
require 'rails_helper'

RSpec.describe Customer, type: :model do
  describe "associations" do
    it { should belong_to(:user).optional }
    it { should belong_to(:company).optional }
    it { should belong_to(:branch).optional }
    it { should have_many(:orders).dependent(:destroy) }
    it { should have_many(:customer_customer_group_appointments).dependent(:destroy) }
    it { should have_many(:customer_groups).through(:customer_customer_group_appointments) }
    it { should have_many(:customer_role_appointments).dependent(:destroy) }
    it { should have_many(:roles).through(:customer_role_appointments) }
    it { should have_many(:customer_service_appointments).dependent(:destroy) }
    it { should have_many(:services).through(:customer_service_appointments) }
    it { should have_many(:customer_membership_appointments).dependent(:destroy) }
    it { should have_many(:memberships).through(:customer_membership_appointments) }
    it { should have_many(:customer_reservation_appointments).dependent(:destroy) }
    it { should have_many(:reservations).through(:customer_reservation_appointments) }
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
  it_behaves_like "property_mapping concern", Customer
end
