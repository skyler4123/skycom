# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::SyncDailyActiveJob do
  subject(:perform_job) { described_class.perform_now }

  let(:log_date) { Date.current }
  let(:active_company) { create(:company, lifecycle_status: :active) }
  let(:suspended_company) do
    create(:company, lifecycle_status: :past_due, suspension_at: 1.day.ago)
  end
  let(:disabled_company) { create(:company, lifecycle_status: :disabled) }

  before do
    active_company
    suspended_company
    disabled_company
  end

  it "logs an active-day for the active company" do
    perform_job
    expect(DailyActiveLog.exists?(company: active_company, log_date: log_date)).to be true
  end

  it "does not log for a suspended company" do
    perform_job
    expect(DailyActiveLog.exists?(company: suspended_company, log_date: log_date)).to be false
  end

  it "does not log for a disabled company" do
    perform_job
    expect(DailyActiveLog.exists?(company: disabled_company, log_date: log_date)).to be false
  end

  it "is idempotent across multiple runs (unique index collapses duplicates)" do
    described_class.perform_now
    described_class.perform_now
    described_class.perform_now

    count = DailyActiveLog.where(company: active_company, log_date: log_date).count
    expect(count).to eq(1)
  end

  it "accepts a custom log_date" do
    past_date = 5.days.ago.to_date
    described_class.perform_now(log_date: past_date)
    expect(DailyActiveLog.exists?(company: active_company, log_date: past_date)).to be true
  end

  it "isolates failures so one bad company does not abort the batch" do
    other_active = create(:company, lifecycle_status: :active)
    allow_any_instance_of(Company).to receive(:is_accessible?) do |company|
      company.id == active_company.id ? raise(StandardError, "boom") : true
    end

    expect { perform_job }.not_to raise_error
    # The other active company should still be logged despite active_company raising
    expect(DailyActiveLog.exists?(company: other_active, log_date: log_date)).to be true
  end
end
