# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Company credit status", type: :model do
  describe "signup promo credits" do
    let(:company) { create(:company) }

    it "starts with the configured promo credit balance" do
      expect(company.company_wallet.promo_credit_balance).to eq(SIGNUP_PROMO_CREDITS)
    end

    it "starts active because the signup promo is positive" do
      expect(company.workflow_status).to eq("active")
      expect(company).not_to be_suspended
    end
  end

  describe "#sync_credit_status!" do
    let(:company) { create(:company) }

    before do
      company.company_wallet.update_columns(main_credit_balance: 0, promo_credit_balance: 0)
    end

    it "suspends the company when the total credit is zero" do
      company.sync_credit_status!(total_credit_balance: 0)

      expect(company.reload.workflow_status).to eq("suspend")
    end

    it "suspends the company when the total credit is negative" do
      company.sync_credit_status!(total_credit_balance: -2)

      expect(company.reload.workflow_status).to eq("suspend")
    end

    it "activates the company when the total credit is positive" do
      company.update!(workflow_status: :suspend)

      company.sync_credit_status!(total_credit_balance: 1)

      expect(company.reload.workflow_status).to eq("active")
    end

    it "reactivates a disabled company when credit becomes positive" do
      company.update!(workflow_status: :disabled)

      company.sync_credit_status!(total_credit_balance: 10)

      expect(company.reload.workflow_status).to eq("active")
    end

    it "leaves system-owned companies active" do
      user = create(:user, :company_owner)
      system_company = Seed::CompanyService.new(
        user: user,
        business_type: :retail,
        workflow_status: :active
      ).tap { |c| c.system_owned = true }
      system_company.save!
      system_company.company_wallet.update_columns(promo_credit_balance: 0)

      system_company.sync_credit_status!(total_credit_balance: 0)

      expect(system_company.reload.workflow_status).to eq("active")
    end
  end

  describe "#suspended?" do
    let(:company) { create(:company) }

    it "caches the boolean in ram_cache and refreshes it when the status changes" do
      company.update!(workflow_status: :suspend)

      expect(company.suspended?).to be(true)
      expect(Rails.ram_cache.read(CacheKeyService.company_suspended(company.id))).to be(true)

      company.update!(workflow_status: :active)

      expect(company.suspended?).to be(false)
      expect(Rails.ram_cache.read(CacheKeyService.company_suspended(company.id))).to be(false)
    end
  end

  describe ".for_background_jobs" do
    it "includes active and suspended companies but excludes disabled companies" do
      active = create(:company)
      suspended = create(:company).tap { |c| c.update!(workflow_status: :suspend) }
      disabled = create(:company).tap { |c| c.update!(workflow_status: :disabled) }

      ids = Company.for_background_jobs.pluck(:id)

      expect(ids).to include(active.id, suspended.id)
      expect(ids).not_to include(disabled.id)
    end
  end

  describe "workflow status enum" do
    it "defines the company-specific statuses with documented values" do
      expect(Company.workflow_statuses).to eq(
        "active" => 0,
        "disabled" => 1,
        "suspend" => 2
      )
    end

    it "defaults to active" do
      expect(Company.new.workflow_status).to eq("active")
    end
  end
end
