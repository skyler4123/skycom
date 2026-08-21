# frozen_string_literal: true

# Seeds dev-mode credit data for a company so dashboards show a non-zero
# wallet, purchase history, and usage history. Called by the enrich services.
#
# The wallet top-up runs through the real chain (CompanyOrder →
# CompanyInvoice → CompanyTransaction) so invoice derivation, order
# completion, and wallet logs are exercised — never direct balance writes.
module Seed
  class CreditDataService
    DAYS_BACK = 7

    HOUR_RANGES = {
      (0..7)   => (0..2),
      (8..11)  => (5..15),
      (12..16) => (10..25),
      (17..19) => (5..15),
      (20..23) => (0..5)
    }.freeze

    def self.create(company:)
      new(company).create
    end

    def initialize(company)
      @company = company
    end

    def create
      puts "Seeding credit data for #{company.name}..."
      seed_wallet_purchases
      seed_daily_usage_history
      seed_monthly_usage_history
      seed_live_delta
      puts "  -> Wallet: #{company.company_wallet.reload.main_credit_balance} credits | " \
           "DailyUsage: #{CompanyDailyUsage.where(company: company).count} | " \
           "MonthlyUsage: #{CompanyMonthlyUsage.where(company: company).count} | " \
           "WalletLogs: #{CompanyWalletLog.where(company: company).count}"
    end

    private

    attr_reader :company

    def seed_wallet_purchases
      payment_method = CompanyPaymentMethod.find_by!(code: "QR_BANK_TRANSFER")

      CREDIT_RATES[company.country.to_sym].first(2).each do |money_cents, credits|
        order = CompanyOrder.create!(
          company: company, user: company.user,
          money_amount_cents: money_cents, credit_amount: credits,
          currency: company.currency
        )
        invoice = CompanyInvoice.create!(
          company: company, company_order: order,
          money_amount_cents: money_cents, credit_amount: credits,
          currency: company.currency
        )
        CompanyTransaction.create!(
          company: company, company_invoice: invoice,
          company_payment_method: payment_method,
          transaction_type: :payment, money_amount_cents: money_cents,
          currency: company.currency, status: :completed,
          gateway_reference: "SEED-#{SecureRandom.hex(6).upcase}"
        )
      end
    end

    def seed_daily_usage_history
      DAYS_BACK.times do |i|
        date = i.days.ago.to_date
        usage = CompanyDailyUsage.find_or_create_for(company, date)
        (0..23).each do |hour|
          range = HOUR_RANGES.find { |hours, _| hours.cover?(hour) }.last
          usage.set_hour_usage(hour, rand(range))
        end
      end
    end

    def seed_monthly_usage_history
      [ today.beginning_of_month, today.prev_month.beginning_of_month ].each do |month|
        usage = CompanyMonthlyUsage.find_or_create_for(company, month)
        last_day = Date.new(month.year, month.month, -1).day
        (1..last_day).each do |day|
          date = Date.new(month.year, month.month, day)
          next if date > today

          value = date.saturday? || date.sunday? ? rand(0..10) : rand(20..60)
          usage.set_day_usage(day, value)
        end
      end
    end

    def seed_live_delta
      company.record_credit_usage!(rand(10..50))
    end

    def today
      Time.current.to_date
    end
  end
end
