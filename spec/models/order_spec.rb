# spec/models/order_spec.rb
require 'rails_helper'

RSpec.describe Order, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:customer).optional }
    it { should have_many(:invoices).dependent(:destroy) }
    it { should have_many(:order_product_appointments).dependent(:destroy) }
    it { should have_many(:products).through(:order_product_appointments) }
    it { should have_many(:order_service_appointments).dependent(:destroy) }
    it { should have_many(:services).through(:order_service_appointments) }
    it { should have_many(:order_product_group_appointments).dependent(:destroy) }
    it { should have_many(:product_groups).through(:order_product_group_appointments) }
    it { should have_many(:order_service_group_appointments).dependent(:destroy) }
    it { should have_many(:service_groups).through(:order_service_group_appointments) }
    it { should have_many(:order_subscription_plan_appointments).dependent(:destroy) }
    it { should have_many(:subscription_plans).through(:order_subscription_plan_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:business_type) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:currency) }
    it { should define_enum_for(:business_type).with_values(online: 0, in_store: 1, phone: 2) }
  end
  it_behaves_like "property_mapping concern", Order
end
