# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::SyncSuspensionJob do
  subject(:perform_job) { described_class.perform_now }

  context "when suspension_at has passed" do
    let!(:company) { create(:company, lifecycle_status: :active, suspension_at: 1.day.ago) }

    it "marks the company as suspended" do
      expect { perform_job }.to change { company.reload.lifecycle_status }
        .from("active").to("suspended")
    end

    it "does not change suspension_at" do
      expect { perform_job }.not_to(change { company.reload.suspension_at })
    end
  end

  context "when suspension_at is in the future" do
    let!(:company) { create(:company, lifecycle_status: :active, suspension_at: 1.day.from_now) }

    it "does not suspend the company" do
      expect { perform_job }.not_to(change { company.reload.lifecycle_status })
    end
  end

  context "when suspension_at is nil" do
    let!(:company) { create(:company, lifecycle_status: :active, suspension_at: nil) }

    it "does not suspend the company" do
      expect { perform_job }.not_to(change { company.reload.lifecycle_status })
    end
  end

  context "when company is already suspended" do
    let!(:company) { create(:company, lifecycle_status: :suspended, suspension_at: 1.day.ago) }

    it "does not change lifecycle_status" do
      expect { perform_job }.not_to(change { company.reload.lifecycle_status })
    end
  end

  context "when company is disabled" do
    let!(:company) { create(:company, lifecycle_status: :disabled, suspension_at: 1.day.ago) }

    it "does not change lifecycle_status" do
      expect { perform_job }.not_to(change { company.reload.lifecycle_status })
    end
  end

  context "with multiple eligible companies" do
    let!(:company1) { create(:company, lifecycle_status: :active, suspension_at: 1.day.ago) }
    let!(:company2) { create(:company, lifecycle_status: :active, suspension_at: 2.days.ago) }

    it "suspends all eligible companies" do
      perform_job
      expect(company1.reload.lifecycle_status).to eq("suspended")
      expect(company2.reload.lifecycle_status).to eq("suspended")
    end
  end

  context "with mixed eligibility" do
    let!(:due) { create(:company, lifecycle_status: :active, suspension_at: 1.day.ago) }
    let!(:future) { create(:company, lifecycle_status: :active, suspension_at: 1.day.from_now) }
    let!(:already_suspended) { create(:company, lifecycle_status: :suspended, suspension_at: 1.day.ago) }

    it "only suspends companies with past deadline" do
      perform_job
      expect(due.reload.lifecycle_status).to eq("suspended")
      expect(future.reload.lifecycle_status).to eq("active")
      expect(already_suspended.reload.lifecycle_status).to eq("suspended")
    end
  end
end
