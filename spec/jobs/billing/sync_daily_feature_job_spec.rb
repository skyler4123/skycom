# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::SyncDailyFeatureJob do
  subject(:perform_job) { described_class.perform_now }

  let(:log_date) { Date.current }
  let!(:active_company) { create(:company) }
  let!(:contract) { active_company.active_billing_contract }
  let!(:feature) do
    resource = create(:billing_resource, :addon_feature, name: "analytics_dashboard")
    create(:contract_feature, billing_contract: contract, billing_resource: resource,
           monthly_flat_price_cents: 500, lifecycle_status: :active)
  end

  before do
    # Ensure contract start is in the past
    contract.update!(start_date: 2.months.ago)
  end

  context "when company is accessible" do
    it "logs a daily feature log for each active feature" do
      expect { perform_job }
        .to change { DailyFeatureLog.where(company: active_company, contract_feature: feature, log_date: log_date).count }
        .from(0).to(1)
    end

    it "logs only active features, not disabled ones" do
      disabled_resource = create(:billing_resource, :addon_feature, name: "inventory_advanced")
      disabled_feature = create(:contract_feature, billing_contract: contract,
        billing_resource: disabled_resource, lifecycle_status: :disabled)

      perform_job
      logged = DailyFeatureLog.where(company: active_company, log_date: log_date)
      expect(logged.pluck(:contract_feature_id)).to include(feature.id)
      expect(logged.pluck(:contract_feature_id)).not_to include(disabled_feature.id)
    end
  end

  context "when company is not accessible" do
    before do
      active_company.update!(suspension_at: 1.day.ago)
    end

    it "does not log a feature log" do
      expect { perform_job }
        .not_to change { DailyFeatureLog.where(company: active_company, log_date: log_date).count }
    end
  end

  context "when company is disabled" do
    before do
      active_company.update!(lifecycle_status: :disabled)
    end

    it "does not log a feature log" do
      expect { perform_job }
        .not_to change { DailyFeatureLog.where(company: active_company, log_date: log_date).count }
    end
  end

  context "idempotency" do
    it "creates only 1 log per company+feature+day across multiple runs" do
      3.times { described_class.perform_now }
      expect(DailyFeatureLog.where(company: active_company, contract_feature: feature, log_date: log_date).count).to eq(1)
    end
  end

  context "with custom log_date" do
    let(:past_date) { 5.days.ago.to_date }

    it "uses the provided date" do
      described_class.perform_now(log_date: past_date)
      expect(DailyFeatureLog.exists?(company: active_company, contract_feature: feature, log_date: past_date)).to be true
    end
  end

  context "failure isolation" do
    let!(:other_active) { create(:company) }
    let!(:other_contract) { other_active.active_billing_contract }

    before do
      other_contract.update!(start_date: 2.months.ago)
      other_resource = create(:billing_resource, :addon_feature, name: "crm_basic")
      create(:contract_feature, billing_contract: other_contract, billing_resource: other_resource,
             monthly_flat_price_cents: 0, lifecycle_status: :active)
    end

    it "continues processing other companies when one fails" do
      allow_any_instance_of(described_class).to receive(:log_features_for_company)
        .with(active_company, anything).and_raise(StandardError, "Boom!")

      expect { perform_job }.not_to raise_error
      expect(DailyFeatureLog.exists?(company: other_active, log_date: log_date)).to be true
    end
  end
end
