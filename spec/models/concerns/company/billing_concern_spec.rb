# frozen_string_literal: true

require "rails_helper"

RSpec.describe Company::BillingConcern do
  subject(:company) { create(:company) }

  let!(:billing_resource) { create(:billing_resource, :addon_feature, name: "inventory_advanced") }
  let!(:volumetric_resource) { create(:billing_resource, :volumetric, name: "orders") }
  let!(:billing_contract) { create(:billing_contract, company: company, lifecycle_status: :active, start_date: 1.month.ago) }

  before do
    Kredis.redis.flushdb
  end

  after do
    Kredis.redis.flushdb
  end

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

  describe "#daily_meter" do
    it "returns a Kredis integer proxy" do
      meter = company.daily_meter("orders")
      expect(meter).to respond_to(:value)
      expect(meter).to respond_to(:value=)
    end

    it "defaults to 0 when no usage exists" do
      expect(company.meter_usage("orders")).to eq(0)
    end

    it "reads accumulated value after record_usage!" do
      company.record_usage!("orders")
      company.record_usage!("orders")
      expect(company.meter_usage("orders")).to eq(2)
    end

    it "falls back to DailyUsageLog when Redis key is missing" do
      company.record_usage!("orders")
      expect(company.meter_usage("orders")).to eq(1)

      Kredis.redis.del("skycom:company:#{company.id}:orders:#{Date.current.strftime('%Y%m%d')}")

      create(:daily_usage_log, company: company, billing_resource: volumetric_resource,
             log_date: Date.current, usage_count: 5)

      expect(company.meter_usage("orders")).to eq(5)
    end

    it "accepts a custom log_date" do
      past_date = 2.days.ago.to_date
      create(:daily_usage_log, company: company, billing_resource: volumetric_resource,
             log_date: past_date, usage_count: 10)
      expect(company.meter_usage("orders", log_date: past_date)).to eq(10)
    end
  end

  describe "#record_usage!" do
    it "increments the meter value" do
      expect { company.record_usage!("orders") }
        .to change { company.meter_usage("orders") }.by(1)
    end

    it "accepts custom quantity" do
      expect { company.record_usage!("orders", quantity: 5) }
        .to change { company.meter_usage("orders") }.by(5)
    end

    it "handles Redis errors gracefully" do
      meter = company.daily_meter("orders")
      allow(meter).to receive(:value).and_raise(Redis::CannotConnectError)
      allow(company).to receive(:daily_meter).and_return(meter)

      expect { company.record_usage!("orders") }.not_to raise_error
    end
  end
end
