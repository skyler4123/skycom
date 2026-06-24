# frozen_string_literal: true

require "rails_helper"

RSpec.describe Company::BillingConcern do
  subject(:company) { create(:company) }

  let!(:billing_resource) { create(:billing_resource, :addon_feature, name: "inventory_advanced") }
  let!(:billing_contract) { create(:billing_contract, company: company, lifecycle_status: :active, start_date: 1.month.ago) }

  describe "#active_billing_contract" do
    it "returns the currently active contract" do
      expect(company.active_billing_contract).to eq(billing_contract)
    end

    context "when no active contract exists" do
      before { billing_contract.update!(lifecycle_status: :expired) }

      it "returns nil" do
        expect(company.active_billing_contract).to be_nil
      end
    end
  end

  describe "#feature_enabled?" do
    context "when feature is assigned to active contract" do
      before do
        create(:contract_feature, billing_contract: billing_contract,
               billing_resource: billing_resource, lifecycle_status: :active)
      end

      it "returns true" do
        expect(company.feature_enabled?("inventory_advanced")).to be true
      end
    end

    context "when feature is not assigned" do
      it "returns false" do
        expect(company.feature_enabled?("inventory_advanced")).to be false
      end
    end

    context "when no active contract exists" do
      before { billing_contract.update!(lifecycle_status: :expired) }

      it "returns false" do
        expect(company.feature_enabled?("inventory_advanced")).to be false
      end
    end

    context "when billing resource does not exist" do
      it "returns false for unknown key" do
        expect(company.feature_enabled?("nonexistent_feature")).to be false
      end
    end
  end

  describe "#wallet_balance_cents" do
    before do
      company.update!(promo_balance_cents: 500, main_balance_cents: 1000)
    end

    it "returns sum of both balances" do
      expect(company.wallet_balance_cents).to eq(1500)
    end
  end

  describe "#debt_ceiling_reached?" do
    before { company.update!(soft_debt_threshold_cents: -1000) }

    it "returns false when balance is above threshold" do
      company.update!(main_balance_cents: 0, promo_balance_cents: 0)
      expect(company.debt_ceiling_reached?).to be false
    end

    it "returns true when balance drops below threshold" do
      company.update!(main_balance_cents: -2000, promo_balance_cents: 0)
      expect(company.debt_ceiling_reached?).to be true
    end
  end

  describe "#record_usage!" do
    it "increments Redis counter" do
      redis_key = "skycom:company:#{company.id}:orders:#{Date.current.strftime('%Y%m%d')}"
      redis = Kredis.redis

      expect(redis).to receive(:incrby).with(redis_key, 1)
      company.record_usage!("orders")
    end

    it "handles Redis errors gracefully" do
      allow(Kredis.redis).to receive(:incrby).and_raise(Redis::BaseConnectionError)
      expect { company.record_usage!("orders") }.not_to raise_error
    end
  end
end
