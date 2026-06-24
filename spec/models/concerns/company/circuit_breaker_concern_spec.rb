# frozen_string_literal: true

require "rails_helper"

RSpec.describe Company::CircuitBreakerConcern do
  subject(:company) { create(:company, lifecycle_status: :active) }

  describe "#circuit_breaker_trip!" do
    it "sets lifecycle_status to suspended" do
      expect { company.circuit_breaker_trip! }
        .to change { company.reload.lifecycle_status }.from("active").to("suspended")
    end

    it "does not change status if already suspended" do
      company.update!(lifecycle_status: :suspended)
      expect { company.circuit_breaker_trip! }
        .not_to change { company.reload.lifecycle_status }
    end
  end

  describe "#circuit_breaker_reset!" do
    before { company.update!(lifecycle_status: :suspended) }

    it "sets lifecycle_status back to active" do
      expect { company.circuit_breaker_reset! }
        .to change { company.reload.lifecycle_status }.from("suspended").to("active")
    end
  end

  describe "auto-reset on balance recovery" do
    before do
      company.update!(lifecycle_status: :suspended, soft_debt_threshold_cents: -1000,
                      main_balance_cents: -5000, promo_balance_cents: 0)
    end

    it "resets to active when balance recovers above threshold" do
      company.update!(main_balance_cents: 0)
      expect(company.reload.lifecycle_status).to eq("active")
    end

    it "does not auto-reset when still below threshold" do
      company.update!(main_balance_cents: -2000)
      expect(company.reload.lifecycle_status).to eq("suspended")
    end
  end
end
