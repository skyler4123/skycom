# frozen_string_literal: true

# Billing portal accessible by blocked companies to view and pay outstanding invoices.
# This controller is exempt from the check_accessable before_action.
#
# Routes (nested under companies):
#   GET  /companies/:company_id/billing      → billing#show (suspended portal)
#   POST /companies/:company_id/billing/pay  → billing#pay_all (pay outstanding invoices)
#
class Companies::BillingController < Companies::ApplicationController
  skip_before_action :check_accessable, only: %i[show pay_all]

  def show
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: billing_show_json }
    end
  end

  private

  def billing_show_json
    company = current_company
    contract = company.active_billing_contract

    period_start = Time.current.beginning_of_month.to_date
    period_end = Time.current.end_of_month.to_date
    days_elapsed = (Date.current - period_start).to_i + 1
    days_remaining = (period_end - Date.current).to_i

    currency = company.currency_code.to_s.upcase

    wallet = {
      main_balance_cents: company.main_balance_cents,
      promo_balance_cents: company.promo_balance_cents,
      total_cents: company.wallet_balance_cents,
      currency: currency
    }

    billing_contract = nil
    daily_metric_totals = {}
    addon_features = []
    estimate = { total_cents: 0, days_remaining: days_remaining, breakdown: {} }

    if contract
      allowances = {}
      unit_prices = {}
      contract.contract_metrics.active.each do |m|
        allowances[m.billing_resource.name] = m.free_allowance
        unit_prices[m.billing_resource.name] = m.unit_price_cents
      end

      feature_prices = {}
      contract.contract_features.active.each do |f|
        feature_prices[f.billing_resource.name] = f.monthly_flat_price_cents
      end

      billing_contract = {
        contract_type: contract.contract_type,
        included_allowance: allowances,
        unit_prices: unit_prices,
        feature_prices: feature_prices
      }

      total_overage_cents = 0
      contract.contract_metrics.active.each do |metric|
        resource_name = metric.billing_resource.name
        current_usage = DailyMetricLog.where(company: company, billing_resource: metric.billing_resource)
                                      .for_period(period_start, Date.current)
                                      .sum(:usage_count)

        projected = days_elapsed > 0 ? (current_usage.to_f / days_elapsed * (days_elapsed + days_remaining)).round : 0
        overage_cents = [ current_usage - metric.free_allowance, 0 ].max * metric.unit_price_cents
        total_overage_cents += overage_cents
        projected_overage_cents = [ projected - metric.free_allowance, 0 ].max * metric.unit_price_cents
        usage_pct = metric.free_allowance > 0 ? (current_usage.to_f / metric.free_allowance * 100).round(1) : 0

        display_unit = "x1000" if resource_name == "api_calls"

        daily_metric_totals[resource_name] = {
          current: current_usage,
          allowance: metric.free_allowance,
          usage_pct: usage_pct,
          projected: projected,
          overage_cents: overage_cents,
          projected_overage_cents: projected_overage_cents,
          unit_price_cents: metric.unit_price_cents,
          display_unit: display_unit
        }
      end

      active_feature_ids = contract.contract_features.active.pluck(:billing_resource_id).to_set

      catalog_addon_features = BillingResource.addon_feature
                                              .where(country_code: company.country_code)
                                              .order(:name)
                                              .map do |resource|
        is_active = active_feature_ids.include?(resource.id)
        active_days = 0

        if is_active
          cf = contract.contract_features.active.find_by(billing_resource: resource)
          active_days = DailyFeatureLog.where(contract_feature: cf)
                                       .for_period(period_start, Date.current)
                                       .count if cf
        end

        {
          key: resource.name,
          name: resource.description.presence || resource.name.humanize,
          monthly_price_cents: resource.price_cents,
          currency: resource.currency,
          active: is_active,
          active_days: active_days
        }
      end

      features_cents = contract.contract_features.active.sum(:monthly_flat_price_cents)

      estimate = {
        total_cents: features_cents + total_overage_cents,
        days_remaining: [ days_remaining, 0 ].max,
        breakdown: {
          features_cents: features_cents,
          overage_cents: total_overage_cents,
          base_cents: contract.fixed_monthly_price_cents
        }
      }
    end

    invoices = company.billing_invoices
                      .where(payment_status: %i[unpaid overdue])
                      .order(:created_at)
                      .map { |inv|
                        {
                          id: inv.id,
                          invoice_number: inv.invoice_number,
                          price_cents: inv.price_cents,
                          price_currency: inv.price_currency,
                          payment_status: inv.payment_status,
                          created_at: inv.created_at
                        }
                      }

    {
      currency: currency,
      company: {
        id: company.id,
        name: company.name,
        lifecycle_status: company.lifecycle_status,
        suspension_at: company.suspension_at,
        is_accessible: company.is_accessible?,
        has_unpaid_invoices: company.has_unpaid_invoices?
      },
      billing_contract: billing_contract,
      wallet: wallet,
      invoices: invoices,
      daily_metric_totals: daily_metric_totals,
      catalog_addon_features: catalog_addon_features,
      estimate: estimate
    }
  end

  public

  def pay_all
    invoices = current_company.billing_invoices
                              .where(payment_status: %i[unpaid overdue])
                              .order(:created_at)

    if invoices.none?
      return render json: { message: "No outstanding invoices.", reactivated: false, remaining_cents: 0 }
    end

    result = Billing::SettlementService.settle_all(current_company)

    company = current_company.reload
    reactivated = company.lifecycle_status_active?

    render json: {
      message: reactivated ? "All invoices paid. Account reactivated!" : "Invoices settled.",
      paid_count: result[:paid_count],
      reactivated: reactivated,
      remaining_cents: result[:remaining_cents]
    }
  end
end
