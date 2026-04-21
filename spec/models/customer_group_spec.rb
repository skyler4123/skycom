# spec/models/customer_group_spec.rb
require 'rails_helper'

RSpec.describe CustomerGroup, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should have_many(:customer_group_appointments).dependent(:destroy) }
    it { should have_many(:customers).through(:customer_group_appointments) }
    it { should have_many(:services).through(:customer_group_appointments) }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
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
    it { should define_enum_for(:business_type).with_values(vip: 0, wholesale: 1, retail: 2, new_customers: 3) }
  end
end
