# frozen_string_literal: true

# Generates 7 days of historical billing data during seeding so the billing
# dashboard shows non-zero usage metrics, meaningful charts, and invoices
# with varied dates. Called by Seed::RetailEnrichService#seeding.
#
#   Seed::BillingDataService.create(company: company)
#
module Seed
  class BillingDataService
    DAYS_BACK = 7

    METRIC_RANGES = {
      "orders"          => (3..15),
      "storage_mb"      => (1..10),
      "employees"       => (2..4),
      "branches"        => (1..2),
      "customers"       => (5..25),
      "api_calls"       => (50..500),
      "stock_mutations" => (1..10)
    }.freeze

    def self.create(company:)
      new(company).create
    end

    def initialize(company)
      @company = company
    end

    def create
      contract = @company.active_billing_contract
      return unless contract

      backdate_contract!(contract)
      attach_paid_features(contract)
      generate_daily_metrics(contract)
      generate_daily_features(contract)
      generate_invoices
    end

    private

    attr_reader :company

    def backdate_contract!(contract)
      past = DAYS_BACK.days.ago
      contract.update_columns(
        start_date: past,
        created_at: past,
        updated_at: past
      )
    end

    PAID_FEATURE_NAMES = %w[hrm_attendance analytics_dashboard].freeze

    def attach_paid_features(contract)
      PAID_FEATURE_NAMES.each do |name|
        resource = BillingResource.find_by(name: name, country_code: company.country_code)
        next unless resource&.addon_feature?

        ContractFeature.find_or_create_by!(
          billing_contract: contract,
          billing_resource: resource
        ) do |feature|
          feature.name = name
          feature.monthly_flat_price_cents = resource.price_cents
          feature.monthly_flat_price_currency = resource.currency
          feature.lifecycle_status = :active
        end
      end
    end

    def generate_daily_metrics(contract)
      metrics = contract.contract_metrics.active.includes(:billing_resource)
      return if metrics.empty?

      (0...DAYS_BACK).reverse_each do |days_ago|
        log_date = days_ago.days.ago.to_date
        created_at = days_ago.days.ago

        metrics.each do |metric|
          range = METRIC_RANGES[metric.billing_resource.name] || (0..5)
          usage = rand(range)

          next if usage <= 0

          record = DailyMetricLog.find_or_create_by!(
            company: company,
            billing_resource: metric.billing_resource,
            log_date: log_date
          ) { |r| r.usage_count = usage }

          record.update_columns(created_at: created_at, updated_at: created_at)
        end
      end
    end

    def generate_daily_features(contract)
      features = contract.contract_features.active.to_a
      return if features.empty?

      (0...DAYS_BACK).reverse_each do |days_ago|
        log_date = days_ago.days.ago.to_date

        features.each do |feature|
          DailyFeatureLog.find_or_create_by!(
            company: company,
            contract_feature: feature,
            log_date: log_date
          )
        end
      end
    end

    def generate_invoices
      return if company.billing_invoices.exists?

      invoice_pairs = [
        { days_ago: 6, status: :paid, price: rand(500..1500) },
        { days_ago: 3, status: :unpaid, price: rand(1000..3000) }
      ]

      invoice_pairs.each do |pair|
        date = pair[:days_ago].days.ago

        invoice = BillingInvoice.create!(
          company: company,
          billing_contract: company.active_billing_contract,
          price_cents: pair[:price],
          price_currency: company.currency_code.to_s.upcase,
          payment_status: pair[:status],
          lifecycle_status: :final,
          period_start: date.beginning_of_month,
          period_end: date.end_of_month
        )

        invoice.update_columns(
          created_at: date,
          updated_at: date
        )

        next unless invoice.paid?

        WalletTransaction.create!(
          company: company,
          billing_invoice: invoice,
          transaction_type: :deduction,
          amount_cents: pair[:price],
          currency: company.currency_code.to_s.upcase,
          balance_before_cents: company.main_balance_cents,
          balance_after_cents: company.main_balance_cents,
          promo_balance_before_cents: company.promo_balance_cents,
          promo_balance_after_cents: company.promo_balance_cents,
          description: "Auto-payment for #{invoice.invoice_number}",
          created_at: date,
          updated_at: date
        )
      end

      company.flag_unpaid! if company.billing_invoices.where(payment_status: %i[unpaid overdue]).exists?
    end
  end
end
