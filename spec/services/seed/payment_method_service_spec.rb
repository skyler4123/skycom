# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::PaymentMethodService do
  describe "ALL_PAYMENT_METHODS" do
    it "includes base payment methods" do
      codes = described_class::ALL_PAYMENT_METHODS.map { |pm| pm[:code] }
      expect(codes).to include("CASH", "STRIPE", "VIETQR")
    end

    it "includes mock payment methods in test environment" do
      codes = described_class::ALL_PAYMENT_METHODS.map { |pm| pm[:code] }
      expect(codes).to include("MOCK_QR", "MOCK_REDIRECT")
    end
  end

  describe ".create" do
    it "creates PaymentMethod records per country" do
      expect { described_class.create }
        .to change(PaymentMethod, :count).by(10) # 5 methods × 2 countries
    end
  end
end

RSpec.describe Seed::BillingPaymentMethodService do
  describe "ALL_RECORDS" do
    it "includes base billing payment methods" do
      codes = described_class::ALL_RECORDS.map { |r| r[:code] }
      expect(codes).to include("CASH", "WALLET_AUTO_DEBIT", "STRIPE_GATEWAY", "VIETQR_GATEWAY")
    end

    it "includes mock billing payment methods in test environment" do
      codes = described_class::ALL_RECORDS.map { |r| r[:code] }
      expect(codes).to include("QR_BANK_TRANSFER", "REDIRECT_SESSION")
    end
  end

  describe ".create" do
    it "creates BillingPaymentMethod records" do
      expect { described_class.create }
        .to change(BillingPaymentMethod, :count).by(6) # 4 base + 2 mock
    end
  end
end

RSpec.describe "GATEWAY_STRATEGIES" do
  it "includes mock strategies in test environment" do
    expect(GATEWAY_STRATEGIES).to include(:mock_qr_gateway, :mock_redirect_gateway)
  end

  it "includes base strategies" do
    expect(GATEWAY_STRATEGIES).to include(:cash, :wallet_auto_debit, :stripe_gateway, :viet_qr_gateway)
  end
end
