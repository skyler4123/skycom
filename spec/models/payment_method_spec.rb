# spec/models/payment_method_spec.rb
require 'rails_helper'

RSpec.describe PaymentMethod, type: :model do
  describe "associations" do
    it { should have_many(:payment_method_appointments).dependent(:destroy) }
    it { should have_many(:branches).through(:payment_method_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:code) }
    it { should validate_presence_of(:business_type) }
    it { should validate_presence_of(:payment_mode) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_uniqueness_of(:code) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(b2c: 0, b2b: 1) }
    it { should define_enum_for(:payment_mode).with_values(qr: 0, redirect: 1, cash: 2) }
  end

  describe "conditional gateway_url validation" do
    let(:pm) { build(:payment_method) }

    it "validates gateway_url presence when payment_mode is not cash" do
      pm.payment_mode = :redirect
      pm.gateway_url = nil
      expect(pm).not_to be_valid
      expect(pm.errors[:gateway_url]).to include("can't be blank")
    end

    it "skips gateway_url validation when payment_mode is cash" do
      pm.payment_mode = :cash
      pm.gateway_url = nil
      expect(pm).to be_valid
    end
  end

  describe "encryption" do
    it "encrypts secret_key" do
      pm = create(:payment_method, secret_key: "sk_test_abc123")
      expect(pm.secret_key).to eq("sk_test_abc123")
      # Verify it's stored encrypted in the database
      raw = PaymentMethod.connection.execute(
        "SELECT secret_key FROM payment_methods WHERE id = '#{pm.id}'"
      ).first["secret_key"]
      expect(raw).not_to eq("sk_test_abc123")
    end
  end
end
