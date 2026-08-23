# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Credit deduction E2E", type: :feature, js: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:branch) { create(:branch) }
  let(:company) { branch.company }
  let(:owner) { company.user }

  let!(:category) do
    Seed::CategoryService.create(company: company, name: "E2E Cat", resource_name: "products")
  end

  before do
    sign_in(owner)

    page.execute_script("localStorage.clear()")

    company_data = JSON.parse(company.to_json).merge(
      "property_mappings" => company.property_mappings.reset.map { |pm| JSON.parse(pm.to_json) },
      "table_configs" => company.table_configs.reset.map { |tc| JSON.parse(tc.to_json) },
      "categories" => company.categories.reset.map { |c| JSON.parse(c.to_json) },
      "branches" => [],
      "departments" => [],
      "roles" => []
    )

    payload = {
      user: JSON.parse(owner.to_json),
      companies: [ company_data ],
      enums: {},
      employees: []
    }

    page.execute_script("localStorage.setItem('client_cache_data', arguments[0])", payload.to_json)
    page.execute_script("localStorage.setItem('client_cache_version', 'forced')")
    page.execute_script("document.cookie = 'client_cache_version=forced; path=/'")
  end

  scenario "dashboard access flows from Kredis delta into CompanyDailyUsage and CompanyMonthlyUsage" do
    snapshot = seed_random_wallet!(company)

    travel_to(Time.zone.local(2026, 8, 18, 14, 5))
    begin
      visit company_dashboards_path(company)
      expect(page).to have_content(company.name, wait: 10)

      # Wait for after_action deduct (JS fetch → JSON) to complete — mirror dashboards/index_spec wait
      expect(page).to have_selector('[data-chart="products"]', wait: 10)

      # Step 2: Redis delta (kredis_counter :credit_usage, app/models/company.rb:146)
      # Poll for delta; Puma thread may still be processing after have_content.
      # Uses polling with sleep (not arbitrary wait) — server-side Kredis, not Capybara UI.
      delta = nil
      10.times do
        delta = company.credit_usage_delta
        break if delta == CREDIT_USAGE_RATES[:access_dashboard]
        sleep 0.2
      end
      expect(delta).to eq(CREDIT_USAGE_RATES[:access_dashboard]) # 2

      # Wallet — promo-first priority (BaseService:65)
      wallet = company.company_wallet.reload
      expect(wallet.promo_credit_balance).to eq(snapshot[:promo_start] - 2)
      expect(wallet.main_credit_balance).to eq(snapshot[:main_start])
      expect(wallet.debt_credit_balance).to eq(0)

      # DB still empty before drain
      expect(CompanyDailyUsage.count).to eq(0)
      expect(CompanyMonthlyUsage.count).to eq(0)

      # Step 3: force sync (periodic via config/recurring.yml, here forced)
      CompanyUsageSyncJob.perform_now

      # Step 4: Redis reset + DB persisted (store_accessor h0..h23 / d1..d31)
      expect(company.credit_usage_delta).to eq(0)
      expect(company.credit_usage.value).to eq(0)

      daily = CompanyDailyUsage.find_by!(company: company, usage_date: Date.new(2026, 8, 18))
      expect(daily.hour_usage(14)).to eq(2) # app/models/company_daily_usage.rb:26
      expect(daily.total_credits).to eq(2) # denormalized sum, ATOMIC_PURPOSE.md debug aid

      monthly = CompanyMonthlyUsage.find_by!(company: company, usage_month: Date.new(2026, 8, 1))
      expect(monthly.day_usage(18)).to eq(2) # app/models/company_monthly_usage.rb:26
      expect(monthly.total_credits).to eq(2)
    ensure
      travel_back
    end
  end

  scenario "accumulates multiple deducts across hourly drains" do
    snapshot = seed_random_wallet!(company, promo_range: 300..600, main_range: 300..600)

    travel_to(Time.zone.local(2026, 8, 18, 14, 5))
    begin
      visit company_dashboards_path(company)
      expect(page).to have_content(company.name, wait: 10)
      expect(page).to have_selector('[data-chart="products"]', wait: 10)

      visit company_dashboards_path(company)
      expect(page).to have_content(company.name, wait: 10)
      expect(page).to have_selector('[data-chart="products"]', wait: 10)

      delta = nil
      10.times do
        delta = company.credit_usage_delta
        break if delta == 4
        sleep 0.2
      end
      expect(delta).to eq(4)
      expect(company.company_wallet.reload.promo_credit_balance).to eq(snapshot[:promo_start] - 4)
      expect(company.company_wallet.reload.main_credit_balance).to eq(snapshot[:main_start])
      expect(company.company_wallet.reload.debt_credit_balance).to eq(0)

      CompanyUsageSyncJob.perform_now

      expect(company.credit_usage_delta).to eq(0)
      daily = CompanyDailyUsage.find_by!(company: company, usage_date: Date.new(2026, 8, 18))
      expect(daily.total_credits).to eq(4)
      expect(daily.hour_usage(14)).to eq(4)

      monthly = CompanyMonthlyUsage.find_by!(company: company, usage_month: Date.new(2026, 8, 1))
      expect(monthly.total_credits).to eq(4)
      expect(monthly.day_usage(18)).to eq(4)

      travel_to(Time.zone.local(2026, 8, 18, 15, 5))
      visit company_dashboards_path(company)
      expect(page).to have_content(company.name, wait: 10)
      expect(page).to have_selector('[data-chart="products"]', wait: 10)

      delta2 = nil
      10.times do
        delta2 = company.credit_usage_delta
        break if delta2 == 2
        sleep 0.2
      end
      expect(delta2).to eq(2)

      CompanyUsageSyncJob.perform_now

      daily = CompanyDailyUsage.find_by!(company: company, usage_date: Date.new(2026, 8, 18))
      expect(daily.hour_usage(15)).to eq(2)
      expect(daily.total_credits).to eq(6)

      monthly = CompanyMonthlyUsage.find_by!(company: company, usage_month: Date.new(2026, 8, 1))
      expect(monthly.day_usage(18)).to eq(6)
      expect(monthly.total_credits).to eq(6)
      expect(company.credit_usage_delta).to eq(0)
    ensure
      travel_back
    end
  end
end
