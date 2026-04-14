# spec/models/order_spec.rb
require 'rails_helper'

RSpec.describe Order, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:customer).optional }
    it { should have_many(:invoices).dependent(:destroy) }
    it { should have_many(:order_appointments).dependent(:destroy) }
    it { should have_many(:products).through(:order_appointments) }
    it { should have_many(:services).through(:order_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:currency_code) }
    it { should validate_presence_of(:business_type) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:currency_code) }
    it { should define_enum_for(:business_type).with_values(online: 0, in_store: 1, phone: 2) }
  end
end
