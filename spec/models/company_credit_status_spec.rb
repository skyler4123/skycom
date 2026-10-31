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

  describe "system company signup promo" do
    it "grants the same signup promo as a normal company" do
      user = create(:user, :company_owner)
      system_company = Seed::CompanyService.new(
        user: user,
        business_type: :system,
        workflow_status: :active
      ).tap { |company| company.system_owned = true }
      system_company.save!

      expect(system_company.company_wallet.promo_credit_balance).to eq(SIGNUP_PROMO_CREDITS)
      expect(system_company.company_wallet.main_credit_balance).to eq(0)
      expect(system_company.reload.workflow_status).to eq("active")
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

    it "leaves system-owned companies active at zero and negative balances" do
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

      system_company.sync_credit_status!(total_credit_balance: -5)
      expect(system_company.reload.workflow_status).to eq("active")
    end
  end

  describe "credit state transitions" do
    let(:company) { create(:company) }
    let(:wallet) { company.company_wallet }

    def zero_wallet!
      wallet.update_columns(main_credit_balance: 0, promo_credit_balance: 0)
      company.sync_credit_status!(total_credit_balance: 0)
    end

    it "suspends at zero and reactivates when the signup amount is granted" do
      zero_wallet!
      expect(company.reload.workflow_status).to eq("suspend")

      wallet.add_to!(balance: :promo, amount: SIGNUP_PROMO_CREDITS)

      expect(company.reload.workflow_status).to eq("active")
      expect(wallet.reload.total_credit_balance).to eq(SIGNUP_PROMO_CREDITS)
    end

    it "suspends when a deduction reaches zero" do
      zero_wallet!
      wallet.add_to!(balance: :promo, amount: 10)

      wallet.deduct_from!(balance: :promo, amount: 10)

      expect(company.reload.workflow_status).to eq("suspend")
      expect(wallet.reload.total_credit_balance).to eq(0)
    end

    it "suspends when a deduction pushes the balance negative" do
      zero_wallet!
      wallet.add_to!(balance: :promo, amount: 5)

      wallet.deduct_from!(balance: :promo, amount: 10)

      expect(company.reload.workflow_status).to eq("suspend")
      expect(wallet.reload.total_credit_balance).to eq(-5)
    end

    it "reactivates a negative company when enough credits are added" do
      zero_wallet!
      wallet.add_to!(balance: :promo, amount: 5)
      wallet.deduct_from!(balance: :promo, amount: 10)

      wallet.add_credits!(amount: 20)

      expect(company.reload.workflow_status).to eq("active")
      expect(wallet.reload.total_credit_balance).to eq(15)
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
