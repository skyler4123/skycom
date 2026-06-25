# frozen_string_literal: true

require "rails_helper"

RSpec.describe Company::CircuitBreakerConcern do
  subject(:company) { create(:company, lifecycle_status: :active) }

  before do
    company.update!(soft_debt_threshold_cents: -1000,
                    main_balance_cents: 0, promo_balance_cents: 0)
  end

  describe "#mark_past_due!" do
    it "sets lifecycle_status to past_due" do
      expect { company.mark_past_due! }
        .to change { company.reload.lifecycle_status }.from("active").to("past_due")
    end

    it "is idempotent when already past_due" do
      company.update!(lifecycle_status: :past_due)
      expect { company.mark_past_due! }.not_to raise_error
    end
  end

  describe "#suspend!" do
    it "sets lifecycle_status to suspended" do
      expect { company.suspend! }
        .to change { company.reload.lifecycle_status }.from("active").to("suspended")
    end

    it "is idempotent when already suspended" do
      company.update!(lifecycle_status: :suspended)
      expect { company.suspend! }.not_to raise_error
    end
  end

  describe "#circuit_breaker_reset!" do
    it "sets lifecycle_status from past_due to active" do
      company.update!(lifecycle_status: :past_due)
      expect { company.circuit_breaker_reset! }
        .to change { company.reload.lifecycle_status }.from("past_due").to("active")
    end

    it "sets lifecycle_status from suspended to active" do
      company.update!(lifecycle_status: :suspended)
      expect { company.circuit_breaker_reset! }
        .to change { company.reload.lifecycle_status }.from("suspended").to("active")
    end
  end

  describe "auto-recovery on balance change" do
    before { company.update!(lifecycle_status: :past_due) }

    it "recovers from past_due when balance rises above threshold" do
      company.update!(main_balance_cents: 5000)
      expect(company.reload.lifecycle_status).to eq("active")
    end

    it "recovers from suspended when balance rises above threshold" do
      company.update!(lifecycle_status: :suspended, main_balance_cents: 5000)
      expect(company.reload.lifecycle_status).to eq("active")
    end

    it "stays past_due if balance is still below threshold" do
      company.update!(main_balance_cents: -2000)
      expect(company.reload.lifecycle_status).to eq("past_due")
    end
  end

  describe "#disabled is terminal" do
    before do
      company.update!(lifecycle_status: :disabled, main_balance_cents: 0,
                      promo_balance_cents: 0)
    end

    it "does not allow mark_past_due! on disabled company" do
      expect { company.mark_past_due! }
        .to raise_error(ActiveRecord::RecordInvalid, /disabled/)
    end

    it "stays disabled even with balance recovery" do
      company.update!(main_balance_cents: 5000)
      expect(company.reload.lifecycle_status).to eq("disabled")
    end
  end
end
