# spec/models/product_spec.rb
require 'rails_helper'

RSpec.describe Product, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:brand).optional }
    it { should have_many(:order_appointments).dependent(:destroy) }
    it { should have_many(:orders).through(:order_appointments) }
    it { should have_many(:product_group_appointments).dependent(:destroy) }
    it { should have_many(:product_groups).through(:product_group_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(physical: 0, digital: 1, service_based: 2) }
  end
end
