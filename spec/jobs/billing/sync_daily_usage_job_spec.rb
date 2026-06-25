# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::SyncDailyUsageJob do
  subject(:perform_job) { described_class.perform_now(log_date: log_date) }

  let(:log_date) { Date.current }
  let(:company) { create(:company) }
  let!(:resource) { create(:billing_resource, :volumetric, name: "orders") }
  let(:date_str) { log_date.strftime("%Y%m%d") }
  let(:redis_key) { "skycom:company:#{company.id}:orders:#{date_str}" }

  before do
    Kredis.redis.flushdb
  end

  after do
    Kredis.redis.flushdb
  end

  context "when Redis keys exist for today" do
    before do
      Kredis.redis.set(redis_key, 42)
    end

    it "creates a DailyUsageLog record" do
      expect { perform_job }.to change(DailyUsageLog, :count).by(1)
    end

    it "records the correct usage count" do
      perform_job
      log = DailyUsageLog.last
      expect(log.usage_count).to eq(42)
      expect(log.company).to eq(company)
      expect(log.billing_resource).to eq(resource)
      expect(log.log_date).to eq(log_date)
    end

    it "leaves the Redis key in place (TTL handles clean-up)" do
      perform_job
      expect(Kredis.redis.exists?(redis_key)).to be(true)
    end
  end

  context "when Redis key has zero value" do
    before do
      Kredis.redis.set(redis_key, 0)
    end

    it "does not create a DailyUsageLog" do
      expect { perform_job }.not_to change(DailyUsageLog, :count)
    end
  end

  context "when the key references a deleted company" do
    before do
      Kredis.redis.set("skycom:company:nonexistent:orders:#{date_str}", 10)
    end

    it "skips gracefully without error" do
      expect { perform_job }.not_to raise_error
    end
  end

  context "when no Redis keys exist" do
    it "does nothing" do
      expect { perform_job }.not_to change(DailyUsageLog, :count)
    end
  end
end
