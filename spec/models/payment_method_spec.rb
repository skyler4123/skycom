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

  describe "strategy validation" do
    let(:pm) { build(:payment_method) }

    it "validates strategy presence when not a system payment" do
      pm.payment_mode = :redirect
      pm.strategy = nil
      expect(pm).not_to be_valid
      expect(pm.errors[:strategy]).to include("can't be blank")
    end

    it "skips strategy validation when payment_mode is cash" do
      pm.payment_mode = :cash
      pm.strategy = :cash
      expect(pm).to be_valid
    end
  end

  describe "strategy enum" do
    it do
      should define_enum_for(:strategy).with_values(
        cash: 0, wallet_auto_debit: 1,
        mock_qr_gateway: 10, mock_redirect_gateway: 11,
        stripe_gateway: 12, viet_qr_gateway: 13
      ).with_prefix
    end
  end
end
