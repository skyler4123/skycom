# frozen_string_literal: true

# Generates 7 days of historical billing data during seeding so the billing
# dashboard shows non-zero usage metrics, meaningful charts, and invoices
# with varied dates. Called by Seed::RetailEnrichService#seeding.
#
# Follows the BillingTransaction source-of-truth pattern:
# - Invoices are created as unpaid
# - BillingTransactions settle them and the callback sets payment_status
# - Update balances explicitly (no auto-settlement interference)
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
          feature.currency = resource.currency
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

        # Create invoice as unpaid — the BillingTransaction callback will
        # set payment_status to :paid when we create the transaction below.
        invoice = BillingInvoice.create!(
          company: company,
          billing_contract: company.active_billing_contract,
          price_cents: pair[:price],
          currency: company.currency_code,
          movement_type: :charge,
          target_balance: :main_balance,
          created_by: :system,
          name: "Monthly Billing - #{date.strftime('%B %Y')}",
          period_start: date.beginning_of_month,
          period_end: date.end_of_month,
          payment_status: :unpaid,
          lifecycle_status: :final
        )

        invoice.update_columns(created_at: date, updated_at: date)

        next unless pair[:status] == :paid

        # Use update_columns to set balance without triggering auto-settlement
        wallet = company.billing_wallet
        promo_before = pair[:price]
        wallet.update_columns(promo_balance_cents: promo_before)

        txn = BillingTransaction.create!(
          company: company,
          billing_invoice: invoice,
          billing_payment_method: BillingPaymentMethod.find_by!(code: "WALLET_AUTO_DEBIT"),
          transaction_type: :deduction,
          amount_cents: pair[:price],
          currency: company.currency_code,
          balance_before_cents: wallet.main_balance_cents,
          balance_after_cents: wallet.main_balance_cents,
          promo_balance_before_cents: promo_before,
          promo_balance_after_cents: 0,
          description: "Auto-payment for #{invoice.invoice_number}"
        )

        # Reset balance and backdate records
        wallet.update_columns(promo_balance_cents: 0)
        txn.update_columns(created_at: date, updated_at: date)
        invoice.update_columns(updated_at: date)
      end

      if company.billing_invoices.where(payment_status: %i[unpaid overdue]).exists?
        unpaid_data = invoice_pairs.select { |p| p[:status] == :unpaid }.first
        if unpaid_data
          unpaid_date = unpaid_data[:days_ago].days.ago
          company.billing_wallet.update_columns(
            has_unpaid_invoices_at: unpaid_date,
            suspension_at: unpaid_date.end_of_month
          )
        end
      end
    end
  end
end
