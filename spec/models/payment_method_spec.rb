# spec/models/payment_method_spec.rb
require 'rails_helper'

RSpec.describe PaymentMethod, type: :model do
  describe "associations" do
    it { should have_many(:payment_method_appointments).dependent(:destroy) }
    it { should have_many(:branches).through(:payment_method_appointments) }
  end

  describe "validations" do
    let(:category) { create(:category) }
    let(:valid_attributes) {
      { name: "Test PM", code: "PM-TEST", business_type: :online,
        category: category, property_mapping: category.property_mapping }
    }

    subject(:payment_method) { PaymentMethod.new(valid_attributes) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:code) }
    it { should validate_presence_of(:business_type) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_uniqueness_of(:code) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(online: 0, offline: 1, global: 2) }
  end
end
